//
//  ImportStack.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 19 December 2024.
//  Last changed on 23 February 2026.
//

import Foundation

/// Source of Gedcom lines.
public protocol GedcomSource {
    var name: String { get }
    func makeLineIterator() -> AnyIterator<String>
}

/// Gedcom source for files.
public struct FileGedcomSource: GedcomSource {
    public let path: String  // Path to Gedcom file.
    public var name: String { path }

    /// Make iterator to return lines from a file.
    public func makeLineIterator() -> AnyIterator<String> {
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8)
        else { return AnyIterator { nil } }
        var lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init).makeIterator()
        return AnyIterator { lines.next() }
    }
}

/// Gedcom source for strings.
public struct StringGedcomSource: GedcomSource {
    public let name: String
    public let content: String

    public init(name: String, content: String) {
        self.name = name
        self.content = content
    }

    /// Make iterator to return lines from a string.
    public func makeLineIterator() -> AnyIterator<String> {
        var lines = content.split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init).makeIterator()
        return AnyIterator { lines.next() }
    }
}

/// Reduce the parameters used by the validation functions.
struct ValidationContext {
    let index: RecordIndex
    let keymap: KeyMap
    let source: String
}

/// Load and validate records from a Gedcom source into containers.
func loadValidRecords(from source: GedcomSource, tagMap: TagMap, keyMap: inout KeyMap, errlog: ErrorLog)
-> (index: RecordIndex, persons: RecordList, families: RecordList, header: GedcomNode?)? {

    // Parse source into list of records.
    guard let recordList = loadRecords(from: source, tagMap: tagMap, keyMap: &keyMap, errlog: errlog)
    else { return nil }

    // Check record closure.
    checkKeysAndReferences(records: recordList, path: source.name, keymap: keyMap, errlog: errlog)

    // Create internal structures.
    var index = RecordIndex()
    var persons = RecordList()
    var families = RecordList()
    var header: GedcomNode?
    for root in recordList {
        if let key = root.key { index[key] = root }
        if root.tag == GedcomTag.indi.rawValue { persons.append(root) }
        else if root.tag == GedcomTag.fam.rawValue { families.append(root) }
        else if root.tag == GedcomTag.head.rawValue { header = root }
    }

    // Validate records.
    let context = ValidationContext(index: index, keymap: keyMap, source: source.name)
    validatePersons(persons: persons, context: context, errlog: errlog)
    //validateFamilies(families: families, context: context, errlog: &errlog) {

    return (index, persons, families, header)
}

/// Load Gedcom records from a source; convert lines to data nodes and data nodes to records.
public func loadRecords(from source: GedcomSource, tagMap: TagMap, keyMap: inout KeyMap,
                        errlog: ErrorLog) -> RecordList? {
    guard let dataNodes = loadDataNodes(from: source, tagMap: tagMap, keyMap: &keyMap, errlog: errlog)
    else { return nil }
    return buildRecords(from: dataNodes, keymap: keyMap, errlog: errlog)
}

/// Load Gedcom records from a source; differs from previous by creating a key map.
public func loadRecords(from source: GedcomSource, tagMap: inout TagMap, errlog: inout ErrorLog) -> RecordList? {
    var keyMap = KeyMap()
    return loadRecords(from: source, tagMap: tagMap, keyMap: &keyMap, errlog: errlog)
}

/// Load array of Gedcom nodes from a source; levels are not checked.
func loadDataNodes(from source: GedcomSource, tagMap: TagMap, keyMap: inout KeyMap,
                   errlog: ErrorLog) -> DataNodes<Int>? {
    var nodes = DataNodes<Int>()
    var lineno = 0
    let lines = source.makeLineIterator()
    while let line = lines.next() {
        lineno += 1
        if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
        switch parseLine(from: line) {
        case .success(lev: let level, key: let key, tag: let tag, val: let value):
            let node = GedcomNode(key: key, tag: tagMap.intern(tag: tag), val: value)
            nodes.add(node: node, data: level)
            if level == 0, let key = key { keyMap[key] = lineno }
        case .failure(errmsg: let errmsg):
            let error = Error(type: .syntax, severity: .severe, source: source.name, line: lineno, message: errmsg)
            errlog.append(error)
        }
    }
    return nodes
}

/// Process array of (node, lev) pairs to build a record list; uses lev-based state machine.
func buildRecords(from dataNodes: DataNodes<Int>, keymap: KeyMap, errlog: ErrorLog) -> RecordList {

    enum State { case initial, main, error } // States.
    var state: State = .initial

    var recordList = RecordList()  // Returned records.
    var prevNode: GedcomNode? = nil
    var prevLev = 0
    var curRoot: GedcomNode? = nil

    for (curNode, curLev) in dataNodes {  // Run state machine.
        switch state {
        case .initial:  // Handle first pair.
            if (curLev == 0) {
                curRoot = curNode;  // Set curRoot and goto .main.
                state = .main;
            } else {  // Add error and goto .error.
                let error = Error(type: .syntax, severity: .fatal, message: "First line must have level 0")
                errlog.append(error)
                state = .error
            }
        case .main: // Building records.
            if (curLev == 0) { // Next root.
                recordList.append(curRoot!) // Save record.
                curRoot = curNode; // Root of next record.
            } else if (curLev == prevLev) { // Found sib.
                curNode.dad = prevNode!.dad;
                prevNode!.sib = curNode
            } else if (curLev == prevLev + 1) { // Found kid.
                curNode.dad = prevNode
                prevNode!.kid = curNode
            } else if (curLev < prevLev) { // Found 'uncle'.
                var count = 0;
                while (curLev < prevLev) {
                    count += 1
                    if (count > 100 || prevNode == nil) { // Error in tree structure.
                        let error = Error(type: .syntax, severity: .fatal,
                                          message: "Too many ancestors: mis-formed tree?")
                        errlog.append(error)
                        state = .error
                        break
                    }
                    prevNode = prevNode!.dad
                    prevLev -= 1;
                }
                curNode.dad = prevNode!.dad
                prevNode!.sib = curNode
            } else { // curLevel > prevLevel + 1.
                let error = Error(type: .syntax, severity: .fatal, message: "Invalid level")
                errlog.append(error)
                state = .error
            }
        case .error: // Skip nodes til next 0 lev.
            if curLev == 0 {
                curRoot = curNode  // Root of the next record.
                state = .main
            }
        }
        prevLev = curLev
        prevNode = curNode
    }
    if (state == .main) { // Aappend last record.
        recordList.append(curRoot!)
    }
    return recordList;
}

/// Result returned by parseLine; on success holds Gedcom fields; on failure holds error message.
enum ParseResult {
    case success(lev: Int, key: String?, tag: String, val: String?)
    case failure(errmsg: String)
}

/// Lexer for Gedcom lines; extracts lev, key, tag and val; returns them in a parse result.
func parseLine(from line: String) -> ParseResult {
    let trim = line.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trim.isEmpty else { return .failure(errmsg: "Empty string") }
    guard trim.count <= 255 else { return .failure(errmsg: "Gedcom line is too long") }
    var index = trim.startIndex

    /// Local function to skip white space.
    func skipWhiteSpace() {
        while index < trim.endIndex, trim[index].isWhitespace {
            index = trim.index(after: index)
        }
    }

    // Lev.
    skipWhiteSpace()
    guard index < trim.endIndex, trim[index].isNumber
    else { return .failure(errmsg: "Line does not begin with level") }
    var levString = ""
    while index < trim.endIndex, trim[index].isNumber {
        levString.append(trim[index])
        index = trim.index(after: index)
    }
    guard let lev = Int(levString)
    else { return .failure(errmsg: "Invalid level") }

    // Key if present.
    skipWhiteSpace()
    if index >= trim.endIndex {
        return .failure(errmsg: "Gedcom line is incomplete")
    }
    var key: String? = nil
    if trim[index] == "@" {
        let keyStart = index
        index = trim.index(after: index)
        guard index < trim.endIndex, trim[index] != "@"
        else { return .failure(errmsg: "Illegal key (@@)") }
        while index < trim.endIndex, trim[index] != "@" {
            index = trim.index(after: index)
        }
        guard index < trim.endIndex
        else { return .failure(errmsg: "Gedcom line is incomplete") }
        index = trim.index(after: index) // Skip closing '@'
        guard index < trim.endIndex, trim[index].isWhitespace
        else { return .failure(errmsg: "There must be a space between the key and tag") }
        key = String(trim[keyStart..<index])
        index = trim.index(after: index) // Skip the space
    }
    skipWhiteSpace()
    guard index < trim.endIndex
    else { return .failure(errmsg: "The line is incomplete") }

    // Tag.
    let tagStart = index
    while index < trim.endIndex, !trim[index].isWhitespace {
        index = trim.index(after: index)
    }
    let tag = String(trim[tagStart..<index])

    // Val.
    skipWhiteSpace()
    let val = index < trim.endIndex ? String(trim[index...]) : nil

    return .success(lev: lev, key: key, tag: tag, val: val)
}
