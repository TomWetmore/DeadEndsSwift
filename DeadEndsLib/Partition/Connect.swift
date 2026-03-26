//
//  Connect.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 16 March 2026.
//  Last changed on 25 March 2026.
//

import Foundation

/// Data collected per person key.
public struct ConnectData {
    var ancestors: Int? = nil
    var descendants: Int? = nil
}

public typealias ConnectIndex = [RecordKey: ConnectData]

/// Get numbers of ancestors and descendants for persons in a closed partition.
extension RecordIndex {

    /// Find connection data for a list of root nodes. The list must contain
    /// all persons from a closed partition based on FAMC, FAMS, HUSB, WIFE,
    /// and CHIL links. If the list does not contain a closed partition there
    /// is no guarantee that all connect data will be accurate.
    public func connections(partition: [Root]) -> ConnectIndex {
        var connectIndex: ConnectIndex = [:]
        for root in partition {
            let key = requireKey(on: root)
            if root.tag != GedcomTag.INDI { continue }
            connectIndex[key] = ConnectData()
        }
        for root in partition {
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

    /// Find the number of ancestors of a person which includes finding
    /// the numbers of ancestors for all ancestors. Uses memoization.
    /// If the same ancestors are reached by different paths because of
    /// pedigree collapse ("cousin marriages") the duplicates are counted.
    func numAncestors(of key: RecordKey, connectIndex: inout ConnectIndex) -> Int {

        if let known = connectIndex[key]!.ancestors { return known }
        var result = 0
        for pkey in self.parentKeys(of: key) {
            result += 1 + numAncestors(of: pkey, connectIndex: &connectIndex)
        }
        var data = connectIndex[key]!
        data.ancestors = result
        connectIndex[key] = data
        return result
    }

    /// Find the number of descendants of a person which includes finding the
    /// numbers of descendants for all descendants. Uses memoization.
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

    /// Find all ancestors of a person; argument and results are root nodes.
    /// As currently written (checking the visited set) duplicate ancestors
    /// caused by pedigree collapse ("cousin marriages") are removed.
    public func ancestors(of personRoot: Root) -> [Root] {
        let startKey = requireKey(on: personRoot)
        var visited: Set<RecordKey> = []
        var queue: [RecordKey] = parentKeys(of: startKey)
        var next = 0
        var result: [GedcomNode] = []

        while next < queue.count {
            let key = queue[next]
            next += 1
            // Using the visited set removes duplicate ancestors caused
            // by pedigree collapse. It might be a good idea to have the
            // visited check be optional.
            if visited.contains(key) { continue }
            visited.insert(key)
            // Append that record root to the results list.
            result.append(requireRoot(from: key, tag: GedcomTag.INDI))
            queue.append(contentsOf: parentKeys(of: key))
        }
        return result
    }

    /// Find all ancestors of a person. Argument and results are person structures.
    public func ancestors(of person: Person) -> [Person] {
        let roots = ancestors(of: person.root)
        return roots.compactMap { $0.key.flatMap { self.person(for: $0) } }
    }

    /// Return number of ancestors of a person; argument is a person root.
    public func numAncestors(of personRoot: Root) -> Int {
        return ancestors(of: personRoot).count
    }

    /// Return number of ancestors of a person; argument is a person structure.
    public func numAncestors(of person: Person) -> Int {
        ancestors(of: person.root).count
    }
}

extension RecordIndex {

    /// Find all descendants of a person; argument and results are person roots.
    public func descendants(of personRoot: Root) -> [Root] {
        guard let startKey = personRoot.key
        else { fatalError("INDI node must have a key") }
        var visited: Set<RecordKey> = []
        var queue: [RecordKey] = childrenKeys(ofPersonKey: startKey)
        var next = 0
        var result: [Root] = []

        while next < queue.count {
            let key = queue[next]
            next += 1
            guard !visited.contains(key) else { continue }
            visited.insert(key)
            let root = requireRoot(from: key, tag: GedcomTag.INDI)
            result.append(root)
            queue.append(contentsOf: childrenKeys(ofPersonKey: key))
        }
        return result
    }

    /// Find all descendants of a person; argument and results are person structures.
    public func descendants(of person: Person) -> [Person] {
        let roots = descendants(of: person.root)
        return roots.compactMap { $0.key.flatMap { self.person(for: $0) } }
    }

    /// Return number of descendants of a person; argument is a person root.
    public func numDescendants(of personRoot: Root) -> Int {
        return descendants(of: personRoot).count
    }

    /// Return number of descendants of a person; argument is a person structure.
    public func numDescendants(of person: Person) -> Int {
        descendants(of: person.root).count
    }
}

extension RecordIndex {

    /// Return the keys of the parents of a person.
    func parentKeys(of personKey: RecordKey) -> [RecordKey] {
        guard let root = self[personKey], root.tag == GedcomTag.INDI
        else { fatalError("parentKeys called with non-person key") }
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
        // Get root of the person whose spouse keys are needed.
        let root = requireRoot(from: key, tag: GedcomTag.INDI)
        var result: [RecordKey] = []
        // Iterate over the FAMS nodes in the person.
        for fams in root.kids(withTag: GedcomTag.FAMS) {
            // Get the family root that each FAMS line refers to.
            let famRoot = requireRoot(from: fams, tag: GedcomTag.FAM)
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
        guard let root = self[key], root.tag == GedcomTag.FAM
        else { fatalError("spouseKeys called with a non-family key") }
        var result: [RecordKey] = []
        for spouseNode in root.kids(withTags: [GedcomTag.HUSB, GedcomTag.WIFE]) {
            guard let spouseKey = spouseNode.val
            else { fatalError("HUSB or WIFE node without key")}
            result.append(spouseKey)
        }
        return dedupeKeys(result)
    }

    /// Given a node with a value that is a key, return the root node the key
    /// refers to, checking its type, turning any problems into fatal error.
    func requireRoot(from node: GedcomNode, tag: String) -> Root {
        guard let key = node.val, let root = self[key], root.tag == tag
        else { fatalError("expected \(tag) record referenced by \(node)") }
        return root
    }

    /// Given a record key return the root node it refers to, checking its type,
    /// turning any problems into a fatal error.
    func requireRoot(from key: RecordKey, tag: String) -> Root {
        guard let root = self[key], root.tag == tag
        else { fatalError("expected \(tag) record for key \(key)") }
        return root
    }


}

/// Dedupe the keys in a record list while keeping order.
func dedupeKeys(_ keys: [RecordKey]) -> [RecordKey] {
    var seen = Set<RecordKey>()
    return keys.filter { seen.insert($0).inserted }
}

func requireKey(on root: GedcomNode) -> RecordKey {
    guard let key = root.key
    else { fatalError("expected a key for root record") }
    return key
}
