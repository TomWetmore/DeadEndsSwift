//
//  Connect.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 16 March 2026.
//  Last changed on 28 September 2026.
//

import Foundation

/// The original purpose of this software was to find the most connected
/// Persons (in terms of numbers of ancestors and descendants) in a
/// Database, as a possible way to order those persons in a Gedcom file
/// when exporting a database, writing the most connected Persons first.
///
/// Before connections are found the Persons have been separated into
/// partitions of genealogically closed sets.
///
/// The output order being considered is to output the largest partitions
/// first, smallest partitions last, and for each partion to output from
/// the most connected person to the least.

/// Data collected per person key.

public struct ConnectData {

    var numAncestors: Int? = nil
    var numDescendants: Int? = nil
}

/// Dictionary that maps Person keys to the Person's ConnectData.

public typealias ConnectIndex = [RecordKey: ConnectData]

/// Get number of ancestors and descendants for Persons in a closed partition.
/// using memoization.

extension RecordIndex {

    /// Create the ConnectIndex for a list of Roots. The list must contain all
    /// Persons from a closed partition based on FAMC, FAMS, HUSB, WIFE, and
    /// CHIL links.

    public func connections(partition: [Root]) -> ConnectIndex {

        var connectIndex: ConnectIndex = [:]
        for root in partition {  // Create an empty ConnectData for each Root.
            let key = root.requireKey()
            if root.tag != "INDI" {
                continue  // TODO: Should this be a fatal error?
            }
            connectIndex[key] = ConnectData()
        }
        for root in partition {  // Get the ConnectData for every Person.
            connections(root: root, connectIndex: &connectIndex)
        }
        return connectIndex
    }

    /// Find the ConnectData for a Person, which includes finding the ConnectData
    /// for the Person's ancestors and descendants.

    func connections(root: Root, connectIndex: inout ConnectIndex) {

        guard let key = root.key, root.tag == "INDI" else {
            return
        }
        var data = connectIndex[key]!
        if data.numAncestors == nil {
            data.numAncestors = numAncestors(of: key, connectIndex: &connectIndex)
        }
        if data.numDescendants == nil {
            data.numDescendants = numDescendants(of: key, connectIndex: &connectIndex)
        }
        connectIndex[key] = data
    }

    /// The next two methods use memoization to find the numbers of ancestors
    /// and descendants of all Persons in a closed partition. When a Person is
    /// first visited, the numbers or all its ancestors and descendants are found
    /// and stored in the ConnectIndex. This includes finding the numbers of
    /// ancestors of all ancesters and the numbers of descendants of all
    /// descandants, so no work is needed on later visits.

    /// Find the number of ancestors of a Person, also finding the numbers
    /// of ancestors for all ancestors, using memoization.

    func numAncestors(of key: RecordKey, connectIndex: inout ConnectIndex) -> Int {

        if let known = connectIndex[key]!.numAncestors {
            return known
        }
        var result = 0
        for pkey in self.parentKeys(ofPersonKey: key) {
            result += 1 + numAncestors(of: pkey, connectIndex: &connectIndex)
        }
        var data = connectIndex[key]!
        data.numAncestors = result
        connectIndex[key] = data
        return result
    }

    /// Find the number of descendants of a Person, also finding the numbers
    /// of descendants for all descendants, using memoization.

    func numDescendants(of key: RecordKey, connectIndex: inout ConnectIndex) -> Int {

        if let known = connectIndex[key]!.numDescendants { return known }
        var result = 0
        for ckey in self.childrenKeys(ofPersonKey: key) {
            result += 1 + numDescendants(of: ckey, connectIndex: &connectIndex)
        }
        var data = connectIndex[key]!
        data.numDescendants = result
        connectIndex[key] = data
        return result
    }
}

/// TODO: These lower level methods must be move to better places.

