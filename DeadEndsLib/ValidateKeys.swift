//
//  ValidateKeys.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 21 December 2024.
//  Last changed on 25 April 2025.
//

import Foundation

// checkKeysAndReferences checks that all record keys are unique and that all values that are keys refer to an
// existing record. records: the records to be checked; path: name of Gedom file; keyMap: key to line number map;
// errlog: error log.
func checkKeysAndReferences(records: RootList, path: String, keymap: KeyMap, errlog: inout ErrorLog) {
    var keyset = Set<String>() // All record keys in the records.

    // First pass checks record keys for existance and uniqueness.
    for root in records {
        let type = root.recordType()
        if type == .header || type == .trailer { continue }
        guard let key = root.key else {
            errlog.append(Error(type: .gedcom, severity: .fatal, source: path,
                                message: "Record \(root) is missing a key"))
            continue
        }
        if keyset.contains(key) {
            let line = keymap[key]
            errlog.append(Error(type: .gedcom, severity: .fatal, source: path, line: line!,
                                message: "Duplicate key: \(key)"))
            continue
        }
        keyset.insert(key)
    }

    // Second pass checks all key references found as node values.
    // NOTE: THIS DOES NOT CHECK ANY KEY REFERENCES THAT MIGHT BE IN THE HEAD RECORD.
    for root in records {
        let key = root.key // Can be nil for .header, .trailer or error cases.
        root.traverse { node in
            guard let value = node.value, isKey(value) else { return }
            if !keyset.contains(value) {
                var line = 0
                if let key = key { line = keymap[key]! + node.offset() }
                let error = Error(type: .gedcom, severity: .fatal, source: path, line: line,
                                  message: "Invalid key value: \(value)")
                errlog.append(error)
            }
        }
    }
}

// Extension to Node for tree operations.
extension GedcomNode {

    // traverse traverses the nodes in a tree doing an action. The order is top down, left to right.
    func traverse(_ action: (GedcomNode) -> Void) {
        action(self)
        var child = self.firstChild
        while let curr = child {
            curr.traverse(action)
            child = curr.nextSibling
        }
    }

    // count returns the number of nodes in the tree rooted at this node.
    func count() -> Int {
        var count = 1
        var child = self.firstChild
        while let curchild = child {
            count += curchild.count()
            child = curchild.nextSibling
        }
        return count
    }

    // offset returns the number of nodes before this node in its tree.
    func offset() -> Int {
        var count = 0
        var curNode: GedcomNode? = self
        var loops = 0
        while let node = curNode, let parent = node.parent {
            loops += 1
            if loops > 100000 { fatalError("Cycle detected in tree.") }
            var sibling = parent.firstChild // Count siblings that occur before.
            while let cursibling = sibling, cursibling !== node {
                count += cursibling.count()
                sibling = cursibling.nextSibling
            }
            curNode = parent // Move up tree.
            count += 1 // Include parent.
        }
        return count
    }

    // level returns the level of a node in a tree by getting the length of the path to the root.
    func level() -> Int {
        var level = -1
        var curr: GedcomNode? = self
        while let node = curr {
            curr = node.parent
            level += 1
            if level > 10000 { fatalError("Cycle detected in tree.") }
        }
        return level
    }
}

// isKey returns true if a String has the form of a Gedcom key.
func isKey(_ value: String) -> Bool {
    return value.hasPrefix("@") && value.hasSuffix("@")
}
enum RecordType {
    case header, trailer, person, family, other
}

// TODO: Add source, etc.
extension GedcomNode {
    func recordType() -> RecordType {
        switch self.tag {
        case "INDI":
            return .person
        case "FAM":
            return .family
        case "HEAD":
            return .header
        case "TRLR":
            return .trailer
        default:
            return .other
        }
    }
}
