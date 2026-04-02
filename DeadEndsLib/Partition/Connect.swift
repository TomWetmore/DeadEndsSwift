//
//  Connect.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 16 March 2026.
//  Last changed on 31 March 2026.
//

import Foundation

/// The original purpose of this software is to find the most connected
/// persons (in terms of numbers of ancestors and descendants) in a
/// database, as a possible way to order those persons in a Gedcom file
/// when exporting a database. The idea is to output the most connected
/// persons first.
///
/// Before the connections are computed the persons in the database have
/// been perviously separated into partitions of genealogically closed sets.
///
/// The output order being considered is to output the largest partitions
/// first, smallest partitions last, and for each partion to output from
/// the most connected person to the least.

/// Data collected per person key.
public struct ConnectData {
    var ancestors: Int? = nil
    var descendants: Int? = nil
}

/// Dictionary mapping person keys to the person's connection data.
public typealias ConnectIndex = [RecordKey: ConnectData]

/// Get numbers of ancestors and descendants for persons in a closed partition.
/// The uses memoization.
extension RecordIndex {

    /// Find connection data for a list of root nodes. The list must contain
    /// all persons from a closed partition based on FAMC, FAMS, HUSB, WIFE,
    /// and CHIL links. If the list does not contain a closed partition there
    /// is no guarantee that all connect data will be accurate.
    public func connections(partition: [Root]) -> ConnectIndex {
        var connectIndex: ConnectIndex = [:]
        for root in partition {  // Add an empty connect data entry for every.
            let key = requireKey(on: root)
            if root.tag != GedcomTag.INDI { continue }
            connectIndex[key] = ConnectData()
        }
        for root in partition {  // Get the connection data for every person.
            connections(root: root, connectIndex: &connectIndex)
        }
        return connectIndex
    }

    /// Find connection data for a person which includes finding the
    /// connection data for the person's ancestors and descendants.
    func connections(root: Root, connectIndex: inout ConnectIndex) {
        guard let key = root.key, root.tag == GedcomTag.INDI
        else { return }

        var data = connectIndex[key]!
        if data.ancestors == nil {
            data.ancestors = numAncestors(of: key, connectIndex: &connectIndex)
        }
        if data.descendants == nil {
            data.descendants = numDescendants(of: key, connectIndex: &connectIndex)
        }
        connectIndex[key] = data
    }

    /// The next two methods use memoization to find the numbers of
    /// ancestors and descendants of all persons in a closed partition.
    /// When a person is visited the first time the numbers or all its
    /// ancestors and descendants are found and stored in the connect
    /// data index, and this includes finding the numbers of ancestors
    /// of all ancesters and the numbers of descendants of all
    /// descandants. No work is done on later visits.
    /// There are other methods for finding the numbers of ancestors
    /// and descendants, but these do not use memoization so they
    /// compute the numbers afresh on every call.

    /// Find the number of ancestors of a person, also finding the numbers
    /// of ancestors for all ancestors. Uses memoization.
    func numAncestors(of key: RecordKey, connectIndex: inout ConnectIndex) -> Int {

        if let known = connectIndex[key]!.ancestors { return known }
        var result = 0
        for pkey in self.parentKeys(ofPersonKey: key) {
            result += 1 + numAncestors(of: pkey, connectIndex: &connectIndex)
        }
        var data = connectIndex[key]!
        data.ancestors = result
        connectIndex[key] = data
        return result
    }

    /// Find the number of descendants of a person, also finding the numbers
    /// of descendants for all descendants. Uses memoization.
    func numDescendants(of key: RecordKey, connectIndex: inout ConnectIndex) -> Int {

        if let known = connectIndex[key]!.descendants { return known }
        var result = 0
        for ckey in self.childrenKeys(ofPersonKey: key) {
            result += 1 + numDescendants(of: ckey, connectIndex: &connectIndex)
        }
        var data = connectIndex[key]!
        data.descendants = result
        connectIndex[key] = data
        return result
    }
}

extension RecordIndex {

    /// Find all ancestors of a person from its root node.
    public func ancestors(of personRoot: Root) -> [Root] {
        let startKey = requireKey(on: personRoot)
        var seen: Set<RecordKey> = []
        var queue: [RecordKey] = parentKeys(ofPersonKey: startKey)
        var next = 0
        var result: [GedcomNode] = []

        while next < queue.count {
            let key = queue[next]
            next += 1
            if seen.contains(key) { continue }  // Handle pedigree collapse.
            seen.insert(key)
            result.append(requireRoot(from: key, tag: GedcomTag.INDI))
            queue.append(contentsOf: parentKeys(ofPersonKey: key))
        }
        return result
    }

    /// Find all ancestors of a person.
    public func ancestors(of person: Person) -> [Person] {
        let roots = ancestors(of: person.root)
        return roots.compactMap { $0.key.flatMap { self.person(for: $0) } }
    }

    /// Return the number of ancestors of a person from its root node.
    public func numAncestors(of personRoot: Root) -> Int {
        return ancestors(of: personRoot).count
    }

    /// Return the number of ancestors of a person.
    public func numAncestors(of person: Person) -> Int {
        ancestors(of: person.root).count
    }
}

extension RecordIndex {

    /// Find all descendants of a person from its root node.
    public func descendants(of personRoot: Root) -> [Root] {
        let startKey = requireKey(on: personRoot)
        var seen: Set<RecordKey> = []
        var queue: [RecordKey] = childrenKeys(ofPersonKey: startKey)
        var next = 0
        var result: [Root] = []

        while next < queue.count {
            let key = queue[next]
            next += 1
            if seen.contains(key) { continue }  // Unusual.
            seen.insert(key)
            result.append(requireRoot(from: key, tag: GedcomTag.INDI))
            queue.append(contentsOf: childrenKeys(ofPersonKey: key))
        }
        return result
    }

    /// Find all descendants of a person.
    public func descendants(of person: Person) -> [Person] {
        let roots = descendants(of: person.root)
        return roots.compactMap { $0.key.flatMap { self.person(for: $0) } }
    }

    /// Return the number of descendants of a person from its root node.
    public func numDescendants(of personRoot: Root) -> Int {
        return descendants(of: personRoot).count
    }

    /// Return the number of descendants of a person.
    public func numDescendants(of person: Person) -> Int {
        descendants(of: person.root).count
    }
}

extension RecordIndex {

    /// Return the keys of the parents of a person.
    func parentKeys(ofPersonKey key: RecordKey) -> [RecordKey] {
        let root = requireRoot(from: key, tag: GedcomTag.INDI)
        var result: [RecordKey] = []

        for famc in root.kids(withTag: GedcomTag.FAMC) {
            guard let famKey = famc.val, let famRoot = self[famKey],
                  famRoot.tag == GedcomTag.FAM
            else { fatalError("invalid FAMC link") }
            for parNode in famRoot.kids(withTags: [GedcomTag.HUSB, GedcomTag.WIFE]) {
                guard let parKey = parNode.val, let parRoot = self[parKey],
                      parRoot.tag == GedcomTag.INDI
                else { fatalError("unexpected node in INDI") }
                result.append(parKey)
            }
        }
        return dedupeKeys(result)
    }

    /// Return the keys of the spouses of a person key.
    func spouseKeys(ofPersonKey key: RecordKey) -> [RecordKey] {
        let root = requireRoot(from: key, tag: GedcomTag.INDI)  // Person root.
        var result: [RecordKey] = []

        for fams in root.kids(withTag: GedcomTag.FAMS) {  // Iterate FAMS nodes.
            let famRoot = requireRoot(from: fams, tag: GedcomTag.FAM)  // Family root.
            // Iterate over the HUSB and WIFE nodes in the family.
            for spouseNode in famRoot.kids(withTags: [GedcomTag.HUSB, GedcomTag.WIFE]) {
                let spouseRoot = requireRoot(from: spouseNode, tag: GedcomTag.INDI)
                if spouseRoot.key != key {
                    result.append(spouseRoot.key!)
                }
            }
        }
        return dedupeKeys(result)
    }

    /// Return the keys of the spouses from a family key.
    func spouseKeys(ofFamilyKey key: RecordKey) -> [RecordKey] {
        let root = requireRoot(from: key, tag: GedcomTag.FAM)
        var result: [RecordKey] = []
        for node in root.kids(withTags: [GedcomTag.HUSB, GedcomTag.WIFE]) {
            result.append(requireKey(on: node))
        }
        return dedupeKeys(result)
    }

    /// Require a node to have a key for its value, require that key to
    /// map to a root node, and return that node. Must succeed.
    func requireRoot(from node: GedcomNode, tag: Tag) -> Root {
        guard let key = node.val, let root = self[key], root.tag == tag
        else { fatalError("expected \(tag) record referenced by \(node)") }
        return root
    }

    /// Require a key to map to a root of optional type, and return that root.
    func requireRoot(from key: RecordKey, tag: Tag? = nil) -> Root {
        guard let root = self[key], root.tag == tag
        else { fatalError("expected root \(key) to refer to a root") }
        if tag == nil { return root }
        guard tag! == root.tag
        else { fatalError("expected root \(root) to have tag \(tag!)") }
        return root
    }
}

/// Dedupe the keys in a list while keeping order.
func dedupeKeys(_ keys: [RecordKey]) -> [RecordKey] {
    var seen = Set<RecordKey>()
    return keys.filter { seen.insert($0).inserted }
}

/// Require a root node to have a key. Must succeed.
func requireKey(on root: GedcomNode, tag: Tag? = nil) -> RecordKey {
    guard let key = root.key
    else { fatalError("expected root \(root) to have a key") }
    if tag == nil { return key }
    guard tag! == root.tag
    else { fatalError("expected root \(root) to have key \(tag!)") }
    return key
}

/// Require a node to be a person root node and have a key.
func requirePersonKey(on root: GedcomNode) -> RecordKey {
    return requireKey(on: root, tag: GedcomTag.INDI)
}

/// Require a node to be a family root and have a key.
func requireFamilyKey(on root: GedcomNode) -> RecordKey {
    return requireKey(on: root, tag: GedcomTag.FAM)
}

