//
//  RefnIndex.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 21 December 2024.
//  Last changed on 8 February 2026.
//

import Foundation

/// Index of REFN values. REFNs at level 1 are indexed.
public struct RefnIndex {

    // Map REFN values to the Gedcom record keys.
    public var index: [String: RecordKey] = [:]

    /// Add an entry to the REFN index; add error to log if the value is mapped to another key.
    public mutating func add(refn: String, key: RecordKey, errLog: ErrorLog? = nil) {
        guard let existingKey = index[refn]
        else {  // Add new entry to index.
            index[refn] = key
            return
        }
    }

    /// Remove a REFN value from the index.
    public mutating func remove(refn: String) {
        index.removeValue(forKey: refn)
    }

    /// Return the record key associated with a REFN value, nil if not found.
    public func getKey(for refn: String) -> String? {
        return index[refn]
    }

    /// Show the REFN index. For test and debug.
    public func showContents() {
        for (refn, key) in index {
            print("REFN \(refn) → Record \(key)")
        }
    }
}

/// Create and validate the refn index.
public func validateRefns(from recordIndex: RecordIndex, keyMap: KeyMap, errLog: ErrorLog) -> RefnIndex {
    var refnIndex = RefnIndex()

    for (_, root) in recordIndex {  // For each record.
        guard let rootKey = root.key else { continue }
        for node in root.kids(withTag: GedcomTag.refn.rawValue) {  // For each 1 REFN node.
            guard let val = node.val, !val.isEmpty else { continue }
            if let existingKey = refnIndex.index[val] {
                if existingKey != rootKey {
                    let line: Int? = keyMap[rootKey].map { $0 + node.offset }
                    let error = Error(type: .gedcom, severity: .fatal, line: line,
                                      message: "Duplicate REFN value \(val) in records \(existingKey) and \(rootKey)")
                    errLog.append(error)
                }
            } else {
                refnIndex.add(refn: val, key: rootKey)
            }
        }
    }
    return refnIndex
}
