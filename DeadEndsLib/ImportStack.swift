//
//  ImportStack.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 19 December 2024.
//  Last changed on 15 October 2026.
//

import Foundation

/// Load a Database from a GedcomSource. If there are errors no Database is created, and
/// an log of the errors is returned.
///
private func loadDatabase(from source: GedcomSource, path: String? = nil,
                          errLog: inout ErrorLog) -> Database? {

    var keyMap = KeyMap()  // Maps record keys to their defining lines in source.
    guard let roots = loadValidRecords(from: source, keyMap: &keyMap, errlog: &errLog)
    else {
        return nil
    }
    return Database(records: roots, path: path)
}

/// Load a Database from a Gedcom file; if there are errors no Database is created.
/// This is the best interface for creating a DeadEnds Database. All you need is a
/// Gedcom file.
///
public func loadDatabase(from path: String, errlog: inout ErrorLog) -> Database? {

    loadDatabase(from: FileGedcomSource(path: path), path: path, errLog: &errlog)
}

/// ValidationContext reduces the numbers parameters needed by the validation functions.
///
struct ValidationContext {
    
    let index: RecordIndex
    let keymap: KeyMap
    let source: String
}

/// Load and validate records from a GedcomSource. Returns a list of root GedcomNodes.
/// If there are errors the list is empty and the ErrorLog holds the errors.
///
func loadValidRecords(from source: GedcomSource, keyMap: inout KeyMap,
                      errlog: inout ErrorLog) -> RootList? {

    // Parse source into unvalidated records.
    guard let roots = loadRecords(from: source, keyMap: &keyMap, errlog: &errlog) else {
        return nil
    }

    // Check key closure. All keys mentioned must refer to existing records.
    checkKeysAndReferences(records: roots, path: source.name, keymap: keyMap, errlog: &errlog)

    // Make index for inter-record validation.
    var index = RecordIndex()
    for root in roots {
        if let key = root.key {
            index[key] = root
        }
    }

    // Validate.
    let context = ValidationContext(index: index, keymap: keyMap, source: source.name)
    validateRecords(roots: roots, context: context, errlog: &errlog)
    return errlog.count == 0 ? roots : nil
}

/// Load records from a GedcomSource; converting lines to DataNodes, and DataNodes to records.
///
public func loadRecords(from source: GedcomSource, keyMap: inout KeyMap,
                        errlog: inout ErrorLog) -> RootList? {

    guard let dataNodes = loadDataNodes(from: source, keyMap: &keyMap, errlog: &errlog)
    else {
        return nil
    }
    return buildRecords(from: dataNodes, keymap: keyMap, errlog: &errlog)
}

/// Load records from a GedcomSource; differs from the previous by creating a key map.
///
public func loadRecords(from source: GedcomSource, errlog: inout ErrorLog) -> RootList? {
    
    var keyMap = KeyMap()
    return loadRecords(from: source, keyMap: &keyMap, errlog: &errlog)
}

/// Load a single record from a string. No semantic validation is done.
///
public func loadRecordFromString(from string: String) -> (root: Root?, errlog: ErrorLog) {

    let source = StringGedcomSource(name: "edit view", content: string)
    var errlog = ErrorLog()

    guard let nodes = loadRecords(from: source, errlog: &errlog) else {
        return (nil, errlog)
    }
    if errlog.count > 0 {
        return (nil, errlog)
    }
    guard nodes.count == 1 else {
        let error = DeadEndsError(type: .gedcom, severity: .severe,
                                  message: "Expected one record in string; found \(nodes.count)")
        errlog.append(error)
        return (nil, errlog)
    }
    return (nodes[0], errlog)
}

/// Load DataNodes from a GedcomSource; levels are not checked.
///
func loadDataNodes(from source: GedcomSource, keyMap: inout KeyMap,
                   errlog: inout ErrorLog) -> DataNodes<Int>? {

    // Associated values are the levels on the Gedcom lines. They are not kept
    // in the GedcomNode object so are needed until the GedcomNodes are built
    // into tree.
    var nodes = DataNodes<Int>()
    var lineno = 0
    let lines = source.makeLineIterator()

    while let line = lines.next() {

        lineno += 1
        if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
        switch parseLine(from: line) {

        case .success(lev: let level, key: let key, tag: let tag, val: let value):
            let node = GedcomNode(key: key, tag: tag, val: value)
            nodes.add(node: node, data: level)
            if level == 0, let key = key {
                keyMap[key] = lineno
            }

        case .failure(errmsg: let errmsg):
            let error = DeadEndsError(type: .syntax, severity: .severe, source: source.name,
                                      line: lineno, message: errmsg)
            errlog.append(error)
        }
    }
    return nodes
}

/// Process the DataNodes to build a RootList; uses a level-based state machine.
///
func buildRecords(from dataNodes: DataNodes<Int>, keymap: KeyMap, errlog: inout ErrorLog)
        -> RootList {

    enum State { case initial, main, error }  // This function is a three state machine.
    var state: State = .initial

    var results = RootList()
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
                let error = DeadEndsError(type: .syntax, severity: .fatal,
                                          message: "First line must have level 0")
                errlog.append(error)
                state = .error
            }

        case .main: // Building records.
            if (curLev == 0) { // Next root.
                results.append(curRoot!) // Save record.
                curRoot = curNode; // Root of next record.
            } else if (curLev == prevLev) { // Found sib.
                curNode.dad = prevNode!.dad;
                prevNode!.sib = curNode
            } else if (curLev == prevLev + 1) { // Found kid.
                curNode.dad = prevNode
                prevNode!.kid = curNode
            } else if (curLev < prevLev) { // Found unc.
                var count = 0;
                while (curLev < prevLev) {
                    count += 1
                    if (count > 100 || prevNode == nil) { // Error in tree structure.
                        let error = DeadEndsError(type: .syntax, severity: .fatal,
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
                let error = DeadEndsError(type: .syntax, severity: .fatal, message: "Invalid level")
                errlog.append(error)
                state = .error
            }

        case .error: // Skip nodes til next 0 level.
            if curLev == 0 {
                curRoot = curNode  // Root of the next record.
                state = .main
            }
        }
        prevLev = curLev
        prevNode = curNode
    }
    if (state == .main) { // Append last record.
        results.append(curRoot!)
    }
    return results;
}


