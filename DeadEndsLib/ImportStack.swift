//
//  ImportStack.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 19 December 2024.
//  Last changed on 12 September 2025.
//

import Foundation

/// Generalizes sources of Gedcom lines.
public protocol GedcomSource {
    var name: String { get }  // A source needs a name for error messages.
    func makeLineIterator() -> AnyIterator<String>
}

/// GedcomSource for UNIX files.
public struct FileGedcomSource: GedcomSource {
    public let path: String  // Path to Gedcom file.
    public var name: String { path }

    public func makeLineIterator() -> AnyIterator<String> {
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8)
        else { return AnyIterator { nil } }
        var lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init).makeIterator()
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
        var lines = content.split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init).makeIterator()
        return AnyIterator { lines.next() }
    }
}

/// Reduces the parameters used by the validation functions.
struct ValidationContext {
    let index: RecordIndex
    let keymap: KeyMap
    let source: String
}

/// Loads and validates records from a GedcomSource into containers.
///
/// Parameters
/// - path: path to the Gedcom file.
/// - tagmap: TagMap ([String: String]) holding unique string for all keys in database.
/// - keymap: KeyMap ([String: Int]]) that maps record keys to their starting line numbers.
/// - errorlog: ErrorLog ([Error]) that holds Error's found.
func loadValidRecords(from source: GedcomSource, tagMap: inout TagMap, keyMap: inout KeyMap, errlog: inout ErrorLog)
-> (index: RecordIndex, persons: RecordList, families: RecordList, header: GedcomNode?)? {

    // Parse the source into a list of records (Gedcom trees).
    guard let recordList = loadRecords(from: source, tagMap: &tagMap, keyMap: &keyMap, errlog: &errlog
    ) else { return nil }

    // Check key closure: all records referred to must exist.
    checkKeysAndReferences(records: recordList, path: source.name, keymap: keyMap, errlog: &errlog)

    // Create internal structures.
    var index = RecordIndex()
    var persons = RecordList()
    var families = RecordList()
    var header: GedcomNode?
    for root in recordList {
        if let key = root.key { index[key] = root }
        if root.tag == "INDI" { persons.append(root) }
        else if root.tag == "FAM" { families.append(root) }
        else if root.tag == "HEAD" { header = root }
    }

    // Validate person and family records.
    let context = ValidationContext(index: index, keymap: keyMap, source: source.name)
    validatePersons(persons: persons, context: context, errlog: &errlog)
    //validateFamilies(records: rootList, keymap: keymap, errlog: &errlog) {

    return (index, persons, families, header)
}

/// Loads the Gedcom records from a GedcomSource.
/// It converts lines to data nodes, then data nodes to root records.
public func loadRecords(from source: GedcomSource, tagMap: inout TagMap, keyMap: inout KeyMap,
                                 errlog: inout ErrorLog) -> RecordList? {
    guard let dataNodes = loadDataNodes(from: source, tagMap: &tagMap, keyMap: &keyMap, errlog: &errlog)
    else { return nil }
    return buildRecords(from: dataNodes, keymap: keyMap, errlog: &errlog)
}

/// Loads the Gedcom records from a GedcomSource. Differs from previous by creating a KeyMap.
public func loadRecords(from source: GedcomSource, tagMap: inout TagMap, errlog: inout ErrorLog) -> RecordList? {
    var keyMap = KeyMap()
    return loadRecords(from: source, tagMap: &tagMap, keyMap: &keyMap, errlog: &errlog)
}

/// Gets the Array of GedcomNodes from a GedcomSource's lines. The levels are not checked yet.
func loadDataNodes(from source: GedcomSource, tagMap: inout TagMap, keyMap: inout KeyMap,
                            errlog: inout ErrorLog) -> DataNodes<Int>? {
    var nodes = DataNodes<Int>()
    var lineno = 0
    let lines = source.makeLineIterator()
    while let line = lines.next() {
        lineno += 1
        if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
        switch parseLine(from: line) {
        case .success(level: let level, key: let key, tag: let tag, value: let value):
            let node = GedcomNode(key: key, tag: tagMap.intern(tag: tag), value: value)
            nodes.add(node: node, data: level)
            if level == 0, let key = key { keyMap[key] = lineno }
        case .failure(errmsg: let errmsg):
            let error = Error(type: .syntax, severity: .severe, source: source.name, line: lineno, message: errmsg)
            errlog.append(error)
        }
    }
    return nodes
}

/// Processes an Array of (Node, level) pairs to build an Array of Gedcom records. It uses the
/// levels to guide the record building state machine.
func buildRecords(from dataNodes: DataNodes<Int>, keymap: KeyMap, errlog: inout ErrorLog) -> RecordList {
    enum State { case initial, main, error } // Record building states.
    var state: State = .initial
    var recordList = RecordList()    // Array of records.
    var pnode: GedcomNode? = nil // Previous node.
    var plevel = 0               // Previous level.
    var rnode: GedcomNode? = nil // Current root.

    for (node, level) in dataNodes {  // This loop is the record building state machine.
        switch state {
        case .initial: // Handle first pair; level must be 0).
            if (level == 0) {
                rnode = node; // Set current root and goto .main.
                state = .main;
            } else { // Issue error and goto .error.
                let error = Error(type: .syntax, severity: .fatal, message: "First line must have level 0")
                errlog.append(error)
                state = .error
            }
        case .main: // Builds records from the (Node, level)'s.
            if (level == 0) { // Found next root.
                recordList.append(rnode!) // Save current root.
                rnode = node; // Set current root for next record.
            } else if (level == plevel) { // Found sibling of previous.
                node.dad = pnode!.dad;
                pnode!.sib = node
            } else if (level == plevel + 1) { // Found child of previous.
                node.dad = pnode
                pnode!.kid = node
            } else if (level < plevel) { // Found uncle of previous.
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
                    pnode = pnode!.dad
                    plevel -= 1;
                }
                node.dad = pnode!.dad
                pnode!.sib = node
            } else { // level > plevel + 1 is illegal
                let error = Error(type: .syntax, severity: .fatal, message: "Invalid level")
                errlog.append(error)
                state = .error
            }
        case .error: // Skip nodes until the next 0 level.
            if level == 0 {
                state = .main
            }
        }
        plevel = level
        pnode = node
    }
    if (state == .main) { // If in .main state at end save the last record.
        recordList.append(rnode!)
    }
    return recordList;
}

/// Type returned by parseLine. On success holds the Gedcom fields. On failure holds an error message.
enum ReadResult {
    case success(level: Int, key: String?, tag: String, value: String?)
    case failure(errmsg: String)
}

/// The lexer for Gedcom lines; extracts the level, key, tag and value of a line, returning them in a ReadResult.
func parseLine(from line: String) -> ReadResult {
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
