//
//  ImportStack.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 19 December 2024.
//  Last changed on 3 February 2026.
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

/// Reduces the parameters used by the validation functions.
struct ValidationContext {
    let index: RecordIndex
    let keymap: KeyMap
    let source: String
}

/// Loads and validates the Records from a GedcomSource into containers.
///
/// Parameters
/// - source: Name of the source.
/// - tagmap: TagMap ([String: String]) holding unique Strings for all keys in the Database.
/// - keymap: KeyMap ([String: Int]]) that maps Record keys to their starting line numbers.
/// - errorlog: ErrorLog ([Error]) that holds Error's found.
func loadValidRecords(from source: GedcomSource, tagMap: inout TagMap, keyMap: inout KeyMap, errlog: inout ErrorLog)
-> (index: RecordIndex, persons: RecordList, families: RecordList, header: GedcomNode?)? {

    // Parse source into list of records.
    guard let recordList = loadRecords(from: source, tagMap: &tagMap, keyMap: &keyMap, errlog: &errlog)
	else { return nil }

    // Check record closure.
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

    // Validate records.
    let context = ValidationContext(index: index, keymap: keyMap, source: source.name)
    validatePersons(persons: persons, context: context, errlog: &errlog)
    //validateFamilies(records: rootList, keymap: keymap, errlog: &errlog) {

    return (index, persons, families, header)
}

/// Load Gedcom records from a source; convert lines to data nodes and data nodes to records.
public func loadRecords(from source: GedcomSource, tagMap: inout TagMap, keyMap: inout KeyMap,
                                 errlog: inout ErrorLog) -> RecordList? {
    guard let dataNodes = loadDataNodes(from: source, tagMap: &tagMap, keyMap: &keyMap, errlog: &errlog)
    else { return nil }
    return buildRecords(from: dataNodes, keymap: keyMap, errlog: &errlog)
}

/// Load Gedcom records from a source; differs from previous by creating a key map.
public func loadRecords(from source: GedcomSource, tagMap: inout TagMap, errlog: inout ErrorLog) -> RecordList? {
    var keyMap = KeyMap()
    return loadRecords(from: source, tagMap: &tagMap, keyMap: &keyMap, errlog: &errlog)
}

/// Load array of Gedcom nodes from a source; levels are not checked.
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

/// Process array of (node, level) pairs to build record array; use levels to guide record building.
func buildRecords(from dataNodes: DataNodes<Int>, keymap: KeyMap, errlog: inout ErrorLog) -> RecordList {

    enum State { case initial, main, error } // Record building states.
    var state: State = .initial

    var recordList = RecordList()  // Array of records.
    var prevNode: GedcomNode? = nil  // Previous node.
    var prevLevel = 0  // Previous level.
    var curRoot: GedcomNode? = nil  // Current root.

    for (curNode, curLevel) in dataNodes {  // State machine.
        switch state {
        case .initial: // Handle first pair.
            if (curLevel == 0) {
                curRoot = curNode; // Set curRoot and goto .main.
                state = .main;
            } else { // Add error and goto .error.
                let error = Error(type: .syntax, severity: .fatal, message: "First line must have level 0")
                errlog.append(error)
                state = .error
            }
        case .main: // Build records from (curNode, curLevel)'s.
            if (curLevel == 0) { // Found next root.
                recordList.append(curRoot!) // Save just built Record.
                curRoot = curNode; // Set curRoot of the next Record.
            } else if (curLevel == prevLevel) { // Found sib of prevNode.
                curNode.dad = prevNode!.dad;
                prevNode!.sib = curNode
            } else if (curLevel == prevLevel + 1) { // Found kid of prevNode.
                curNode.dad = prevNode
                prevNode!.kid = curNode
            } else if (curLevel < prevLevel) { // Found 'uncle' of prevNode.
                var count = 0;
                while (curLevel < prevLevel) {
                    count += 1
                    if (count > 100 || prevNode == nil) { // Error in tree structure.
                        let error = Error(type: .syntax, severity: .fatal,
                                          message: "Too many ancestors: mis-formed tree?")
                        errlog.append(error)
                        state = .error
                        break
                    }
                    prevNode = prevNode!.dad
                    prevLevel -= 1;
                }
                curNode.dad = prevNode!.dad
                prevNode!.sib = curNode
            } else { // curLevel > prevLevel + 1 is illegal.
                let error = Error(type: .syntax, severity: .fatal, message: "Invalid level")
                errlog.append(error)
                state = .error
            }
        case .error: // Skip nodes til next 0 level.
            if curLevel == 0 {
                curRoot = curNode  // Root of the next Record.
                state = .main
            }
        }
        prevLevel = curLevel
        prevNode = curNode
    }
    if (state == .main) { // If in .main append last record.
        recordList.append(curRoot!)
    }
    return recordList;
}

/// Result enum returned by parseLine; on success holds Gedcom fields; on failure holds error message.
enum ReadResult {
    case success(level: Int, key: String?, tag: String, value: String?)
    case failure(errmsg: String)
}

/// Lexer for Gedcom lines; extract level, key, tag and value; return them in a read result.
func parseLine(from line: String) -> ReadResult {
    let trim = line.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trim.isEmpty else { return .failure(errmsg: "Empty string") }
    guard trim.count <= 255 else { return .failure(errmsg: "Gedcom line is too long") }
    var index = trim.startIndex

    // Get level.
    while index < trim.endIndex, trim[index].isWhitespace {  // Skip whitespace.
    		index = trim.index(after: index)
    }
    guard index < trim.endIndex, trim[index].isNumber
    else { return .failure(errmsg: "Line does not begin with level") }
    var levelString = ""
    while index < trim.endIndex, trim[index].isNumber {
        levelString.append(trim[index])
        index = trim.index(after: index)
    }
    guard let level = Int(levelString)
    else { return .failure(errmsg: "Invalid level") }

    // Key if present.
    while index < trim.endIndex, trim[index].isWhitespace {
    		index = trim.index(after: index)
    }
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
    while index < trim.endIndex, trim[index].isWhitespace {
    		index = trim.index(after: index)
    }
    guard index < trim.endIndex
    else { return .failure(errmsg: "The line is incomplete") }

    // Tag.
    let tagStart = index
    while index < trim.endIndex, !trim[index].isWhitespace {
    		index = trim.index(after: index)
    }
    let tag = String(trim[tagStart..<index])
    while index < trim.endIndex, trim[index].isWhitespace {
    		index = trim.index(after: index)
    }
    // Value.
    let value = index < trim.endIndex ? String(trim[index...]) : nil

    return .success(level: level, key: key, tag: tag, value: value)
}
