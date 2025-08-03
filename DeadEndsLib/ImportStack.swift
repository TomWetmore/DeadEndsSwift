//
//  ImportStack.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 19 December 2024.
//  Last changed on 21 July 2025.
//

import Foundation

/// Protocol to generalize sources of Gedcom lines. Currently used for file- and String-based sources.
public protocol GedcomSource {
    var name: String { get }
    func makeLineIterator() -> AnyIterator<String>
}

/// GedcomSource for UNIX files.
public struct FileGedcomSource: GedcomSource {
    public let path: String
    public var name: String { path }

    public func makeLineIterator() -> AnyIterator<String> {
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
            return AnyIterator { nil }
        }
        var lines = contents.split(separator: "\n", omittingEmptySubsequences: false).map(String.init).makeIterator()
        return AnyIterator { lines.next() }
    }
}

/// GedcomSource for Strings.
public struct StringGedcomSource: GedcomSource {
    public let name: String
    public let content: String

    public init(name: String, content: String) {
        self.name = name
        self.content = content
    }

    public func makeLineIterator() -> AnyIterator<String> {
        var lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init).makeIterator()
        return AnyIterator { lines.next() }
    }
}

/// Structure that reduces the parameters needed by validation functions.
struct ValidationContext {
    let index: RecordIndex
    let keymap: KeyMap
    let source: String

    init(index: RecordIndex, keymap: KeyMap, source: String) {
        self.index = index
        self.keymap = keymap
        self.source = source
    }
}

/// Reads a GedcomSource into the main database containers.
///
/// Reads records via `getRecordsFromSource`, and validates then with `checkKeysAndReferences`
///
/// Parameters
/// - `path`: path to the Gedcom file.
/// - `tagmap`: `TagMap` (`[String: String]`) holding unique string for all keys in database.
/// - `keymap`: `KeyMap` (`[String: Int]`]) that maps record keys to their starting line numbers.
/// - `errorlog`: `ErrorLog` (`[Error]`) that holds `Error`'s found.


/// Reads a GedcomSource, validates the records, and returns the structures used to build a Database.
/// Returns nil on error, and appends errors to errlog. The keymap is filled in for error reporting.
func getValidRecordsFromSource(source: GedcomSource, tagmap: inout TagMap, keymap: inout KeyMap, errlog: inout ErrorLog
) -> (index: RecordIndex, persons: RootList, families: RootList)? {

    // Parse the source into a list of root nodes (Gedcom records)
    guard let rootlist = getRecordsFromSource(source: source, tagmap: &tagmap, keymap: &keymap, errlog: &errlog
    ) else { return nil }

    // Check key closure.
    checkKeysAndReferences(records: rootlist, path: source.name, keymap: keymap, errlog: &errlog)

    // Create internal structures; these may change.
    var index = RecordIndex()
    var persons = RootList()
    var families = RootList()
    for root in rootlist {
        if let key = root.key { index[key] = root }
        if root.tag == "INDI" { persons.append(root) }
        if root.tag == "FAM" { families.append(root) }
    }

    // Validate person and family records.
    let context = ValidationContext(index: index, keymap: keymap, source: "")
    validatePersons(persons: persons, context: context, errlog: &errlog)
    //validateFamilies(records: rootList, keymap: keymap, errlog: &errlog) {

    return (index, persons, families)
}

/// Returns the Gedcom records from a GedcomSource.
/// It converts lines to data nodes, then data nodes to root records.
public func getRecordsFromSource(source: GedcomSource, tagmap: inout TagMap, keymap: inout KeyMap, errlog: inout ErrorLog) -> RootList? {
    guard let datanodes = getDataNodesFromSource(source: source, tagmap: &tagmap, keymap: &keymap, errlog: &errlog) else {
        return nil
    }
    return getRecordsFromDataNodes(datanodes: datanodes, keymap: keymap, errlog: &errlog)
}

public func getRecordsFromSource(source: GedcomSource, tagmap: inout TagMap, errlog: inout ErrorLog) -> RootList? {
    var keyMap = KeyMap()
    return getRecordsFromSource(source: source, tagmap: &tagmap, keymap: &keyMap, errlog: &errlog)
}


func getDataNodesFromLines(lines: [String], source: String, tagmap: inout TagMap, keymap: inout KeyMap,
                           errlog: inout ErrorLog) -> DataNodes<Int>? {
    var nodes = DataNodes<Int>()
    var lineno = 0

    for line in lines {
        lineno += 1
        if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }

        switch extractFields(from: line) {
        case .success(let level, let key, let tag, let value):
            let node = GedcomNode(key: key, tag: tagmap.intern(tag: tag), value: value)
            nodes.add(node: node, data: level)
            if level == 0, let key = key { keymap[key] = lineno }
        case .failure(let errmsg):
            errlog.append(Error(type: .syntax, severity: .severe, source: source, line: lineno, message: errmsg))
        }
    }
    return nodes
}

func getDataNodesFromSource(
    source: GedcomSource,
    tagmap: inout TagMap,
    keymap: inout KeyMap,
    errlog: inout ErrorLog
) -> DataNodes<Int>? {
    var nodes = DataNodes<Int>()
    var lineno = 0
    let lines = source.makeLineIterator()

    while let line = lines.next() {
        lineno += 1
        if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            continue
        }
        switch extractFields(from: line) {
        case .success(level: let level, key: let key, tag: let tag, value: let value):
            let node = GedcomNode(key: key, tag: tagmap.intern(tag: tag), value: value)
            nodes.add(node: node, data: level)
            if level == 0, let key = key {
                keymap[key] = lineno
            }
        case .failure(errmsg: let errmsg):
            let error = Error(
                type: .syntax,
                severity: .severe,
                source: source.name,
                line: lineno,
                message: errmsg
            )
            errlog.append(error)
        }
    }

    return nodes
}

/// Processes an Array of (Node, level) pairs from a Gedcom source into an Array of Node
/// trees (aka Records). It requires the levels to guide the tree building.
func getRecordsFromDataNodes(datanodes: DataNodes<Int>, keymap: KeyMap, errlog: inout ErrorLog) -> RootList {
    enum State { case initial, main, error } // Tree building done by state machine.
    var state: State = .initial
    var rootList = RootList() // Array of roots of the constructed Node trees.
    var pnode: GedcomNode? = nil // Previous Node.
    var plevel = 0 // Previous level.
    var rnode: GedcomNode? = nil // Current root.

    for (node, level) in datanodes {
        switch state {
        case .initial: // Handle first pair; level must be 0).
            if (level == 0) {
                rnode = node; // Set current root and enter .main state.
                state = .main;
            } else { // Issue error and enter .error state.
                let error = Error(type: .syntax, severity: .fatal, message: "First line must have level 0")
                errlog.append(error)
                state = .error
            }
        case .main: // Builds Node trees from the (Node, level)'s.
            if (level == 0) { // Found next root.
                rootList.append(rnode!) // Save current Node tree.
                rnode = node; // Set current root of the next tree.
            } else if (level == plevel) { // Found the sibling of previous Node.
                node.parent = pnode!.parent;
                pnode!.sibling = node
            } else if (level == plevel + 1) { // Found the child of previous Node.
                node.parent = pnode
                pnode!.child = node
            } else if (level < plevel) { // Found an uncle of previous Node.
                var count = 0;
                while (level < plevel) {
                    count += 1
                    if (count > 100 || pnode == nil) { // Cycle in tree?
                        let error = Error(type: .syntax, severity: .fatal,
                                          message: "Too many ancestors: mis-formed tree?")
                        errlog.append(error)
                        state = .error
                        break
                    }
                    pnode = pnode!.parent
                    plevel -= 1;
                }
                node.parent = pnode!.parent
                pnode!.sibling = node
            } else { // level > plevel + 1 is illegal
                let error = Error(type: .syntax, severity: .fatal, message: "Invalid level")
                errlog.append(error)
                state = .error
            }
        case .error: // Skip Nodes until the next 0 level.
            if level == 0 {
                state = .main
            }
        }
        plevel = level
        pnode = node
    }
    if (state == .main) { // If in .main state at end save the last Node tree.
        rootList.append(rnode!)
    }
    return rootList;
}

/// Type returned by extractFields. On success holds the Gedcom fields. On failure holds an error message
enum ReadResult {
    case success(level: Int, key: String?, tag: String, value: String?)
    case failure(errmsg: String)
}

/// Extracts the level, key, tag and value from a string holding a single Gedcom line.
func extractFields(from line: String) -> ReadResult {
    let trim = line.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trim.isEmpty else { return .failure(errmsg: "Empty string") }
    guard trim.count <= 255 else { return .failure(errmsg: "Gedcom line is too long") }
    var index = trim.startIndex

    // Get level.
    while index < trim.endIndex, trim[index].isWhitespace { index = trim.index(after: index) } // Skip whitespace.
    guard index < trim.endIndex, trim[index].isNumber else { return .failure(errmsg: "Line does not begin with level") }
    var levelString = ""
    while index < trim.endIndex, trim[index].isNumber {
        levelString.append(trim[index])
        index = trim.index(after: index)
    }
    guard let level = Int(levelString) else { return .failure(errmsg: "Invalid level") }

    // Get key if present.
    while index < trim.endIndex, trim[index].isWhitespace { index = trim.index(after: index) } // Skip whitespace.
    if index >= trim.endIndex { return .failure(errmsg: "Gedcom line is incomplete") }
    var key: String? = nil
    if trim[index] == "@" {
        let keyStart = index
        index = trim.index(after: index)
        guard index < trim.endIndex, trim[index] != "@" else { return .failure(errmsg: "Illegal key (@@)") }
        while index < trim.endIndex, trim[index] != "@" {
            index = trim.index(after: index)
        }
        guard index < trim.endIndex else { return .failure(errmsg: "Gedcom line is incomplete") }
        index = trim.index(after: index) // Skip closing '@'
        guard index < trim.endIndex, trim[index].isWhitespace else {
            return .failure(errmsg: "There must be a space between the key and tag")
        }
        key = String(trim[keyStart..<index])
        index = trim.index(after: index) // Skip the space
    }
    while index < trim.endIndex, trim[index].isWhitespace { index = trim.index(after: index) } // Skip whitespace.
    guard index < trim.endIndex else { return .failure(errmsg: "The line is incomplete") }

    // Get tag.
    let tagStart = index
    while index < trim.endIndex, !trim[index].isWhitespace { index = trim.index(after: index) }
    let tag = String(trim[tagStart..<index])
    while index < trim.endIndex, trim[index].isWhitespace { index = trim.index(after: index) }

    // Get value if present
    let value = index < trim.endIndex ? String(trim[index...]) : nil

    return .success(level: level, key: key, tag: tag, value: value)
}
