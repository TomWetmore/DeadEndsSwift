//
//  ValidateKeys.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 21 December 2024.
//  Last changed on 20 March 2026.
//

import Foundation

// Check that record keys are unique and closed.
func checkKeysAndReferences(records: RootList, path: String, keymap: KeyMap, errlog: ErrorLog) {
    var keyset = Set<String>() // Encountered keys.

    for root in records {  // Existance and uniqueness.
        let type = root.recordKind()
        if type == .header || type == .trailer { continue }
        guard let key = root.key else {  // Existance.
            errlog.append(DeadEndsError(type: .gedcom, severity: .fatal, source: path,
                                message: "Record \(root) is missing a key"))
            continue
        }
        if keyset.contains(key) {  // Uniqueness.
            let line = keymap[key]
            errlog.append(DeadEndsError(type: .gedcom, severity: .fatal, source: path, line: line!,
                                message: "Duplicate key: \(key)"))
            continue
        }
        keyset.insert(key)
    }
    for root in records {  // Check all keys found as values have targets.
        let key = root.key
        root.traverse { node in
            guard let value = node.val, value.isKey else { return }
            if !keyset.contains(value) {
                var line = 0
                if let key = key { line = keymap[key]! + node.offset }
                let error = DeadEndsError(type: .gedcom, severity: .fatal, source: path, line: line,
                                  message: "Invalid key value: \(value)")
                errlog.append(error)
            }
        }
    }
}

/// Extension to Gedcom node for tree operations.
extension GedcomNode {

    /// Traverse a tree top down, left to right, doing an action.
    func traverse(_ action: (GedcomNode) -> Void) {
        action(self)
        var child = self.kid
        while let curr = child {
            curr.traverse(action)
            child = curr.sib
        }
    }

    
}

extension String {

    /// Check if a string is a record key.
    public var isKey: Bool {
        guard count >= 3, hasPrefix("@"), hasSuffix("@") else { return false }
        let inner = dropFirst().dropLast()
        guard !inner.isEmpty else { return false }
        return inner.unicodeScalars.allSatisfy { scalar in
            switch scalar.value {
            case 48...57, 65...90, 97...122: return true // 0-9 A-Z a-z
            default: return false
            }
        }
    }
}

/// Get record kind from root tag.
extension Root {
    func recordKind() -> RecordKind {
        switch self.tag {
        case GedcomTag.INDI:
            return .person
        case "FAM":
            return .family
        case "HEAD":
            return .header
        case "TRLR":
            return .trailer
        case "SOUR":
            return .source
        default:
            return .other
        }
    }
}
