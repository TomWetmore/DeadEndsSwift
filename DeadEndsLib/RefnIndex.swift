//
//  RefnIndex.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 21 December 2024.
//  Last changed on 22 November 2025.
//

import Foundation

public struct RefnIndex {
    // Maps a REFN value to the GEDCOM record key that owns it
    private var index: [String: String] = [:]

    /// Adds a 1 REFN value to the index. Returns `false` if the REFN is already in use.
    @discardableResult
    public mutating func add(refn: String, key: String) -> Bool {
        guard index[refn] == nil else {
            return false // REFN already exists.
        }
        index[refn] = key
        return true
    }

    /// Removes a REFN from the index.
    public mutating func remove(refn: String) {
        index.removeValue(forKey: refn)
    }

    /// Returns the record key associated with a `REFN` value, or `nil` if not found.
    public func getKey(for refn: String) -> String? {
        return index[refn]
    }

    /// Prints the entire REFN index. For debugging.
    public func showContents() {
        for (refn, key) in index {
            print("REFN \(refn) → Record \(key)")
        }
    }
}
