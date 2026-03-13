//
//  RefnIndex.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 21 December 2024.
//  Last changed on 13 March 2026.
//

import Foundation

/// Index of reference values. Only those at level 1 are indexed.
public struct RefnIndex {

    // Map reference values to the Gedcom record keys.
    public var index: [String: Set<RecordKey>] = [:]

    public var count: Int { index.count }

    /// Add an entry to reference index.
    public mutating func add(refn: String, key: RecordKey) {
        index[refn, default: Set()].insert(key)
    }

    /// Remove entry from reference index.
    public mutating func remove(refn: String, key: RecordKey) {
        if var keys = index[refn] {
            keys.remove(key)
            if keys.isEmpty { index.removeValue(forKey: refn) }
            else { index[refn] = keys } // Update record set.
        }
    }

    /// Return set of record keys associated with a reference value.
    public func getKeys(for refn: String) -> Set<RecordKey> {
        guard let set = index[refn] else { return [] }
        return set
    }

    /// Show the reference index. For test and debug.
    public func showContents() {
        for (refn, key) in index {
            print("REFN \(refn) → Record \(key)")
        }
    }
}

/// Build reference index from record index.
public func buildRefnIndex(from index: RecordIndex) -> RefnIndex {
    var refnIndex = RefnIndex()

    for root in index.values {
        guard let recordKey = root.key else { continue }  // Will succeed.
        for node in root.kids(withTag: "REFN") {
            guard let refn = node.val, !refn.isEmpty else { continue }  // Allow empty values.
            refnIndex.add(refn: refn, key: recordKey)
        }
    }
    return refnIndex
}
