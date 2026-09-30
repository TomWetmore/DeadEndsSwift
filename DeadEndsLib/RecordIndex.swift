//
//  RecordIndex.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 16 March 2026.
//  Last changed on 29 September 2026.

import Foundation

/// Index of Gedcom records. Wraps a dictionary that maps RecordKeys (Strings) to
/// Roots (0 level GedcomNodes).

public struct RecordIndex {

    private var table: [RecordKey: Root] = [:]  // Representation.

    /// Returns a record index with an empty table.
    public init() {}

    /// Returns a record index with an established table.
    public init(_ table: [RecordKey: Root]) {
        self.table = table
    }

    /// Passes the subscript operator down to the table.
    public subscript(key: RecordKey) -> Root? {
        get { table[key] }
        set { table[key] = newValue }
    }

    public var count: Int { table.count }
    public var keys: Dictionary<RecordKey, Root>.Keys { table.keys }
    public var values: Dictionary<RecordKey, Root>.Values { table.values }
    public mutating func removeValue(forKey key: RecordKey) { table.removeValue(forKey: key) }
    public func contains(_ key: RecordKey) -> Bool { table[key] != nil }
}

extension RecordIndex: Sequence {

    public func makeIterator() -> Dictionary<RecordKey, Root>.Iterator {
        table.makeIterator()
    }
}

/// Extension for record retrieval from indexes.
extension RecordIndex {

    /// Try to create a Person from a Root node.

    public func person(for key: String) -> Person? {
        
        guard let node = self[key], node.tag == "INDI" else {
            return nil
        }
        return Person(node)
    }

    /// Try to create a Family from a Root node.

    public func family(for key: String) -> Family? {

        guard let node = self[key], node.tag == "FAM" else {
            return nil
        }
        return Family(node)
    }
}

extension Root {

    /// Return a person with the root self.
    var asPerson: Person {
        return Person(self)
    }
}

extension RecordIndex {

    /// Return all persons with a set of roles in the family in Gedcom order.
    private func people(in family: Family, roles: Set<Tag>) -> [Person] {
        var out: [Person] = []
        var seen = Set<RecordKey>()

        for node in family.root.kids {
            guard roles.contains(where: { $0 == node.tag }) else { continue }
            guard let key = node.val else { continue }
            guard seen.insert(key).inserted else { continue }
            if let person = person(for: key) { out.append(person) }
        }
        return out
    }
}

/// Children key level.
extension RecordIndex {

    /// Return the keys of the children of a person with the given key.
    func childrenKeys(ofPersonKey key: RecordKey) -> [RecordKey] {
        let perRoot = requireRoot(from: key, tag: GedcomTag.INDI)
        var results: [RecordKey] = []

        for famsNode in perRoot.kids(withTag: GedcomTag.FAMS) {
            let famsRoot = requireRoot(from: famsNode, tag: GedcomTag.FAM)
            for chilNode in famsRoot.kids(withTag: GedcomTag.CHIL) {
                let chilRoot = requireRoot(from: chilNode, tag: GedcomTag.INDI)
                guard let chilKey = chilRoot.key
                else { fatalError("child root \(chilRoot) without a key") }
                results.append(chilKey)
            }
        }
        return dedupeKeys(results)
    }

    /// Return the children of a family using keys.
    func childrenKeys(ofFamilyKey key: RecordKey) -> [RecordKey] {
        let famRoot = requireRoot(from: key, tag: GedcomTag.FAM)
        var result: [RecordKey] = []

        for chilNode in famRoot.kids(withTag: GedcomTag.CHIL) {
            let chilRoot = requireRoot(from: chilNode, tag: GedcomTag.INDI)
            guard let chilKey = chilRoot.key
            else { fatalError("child root \(chilRoot) without a key")}
            result.append(chilKey)
        }
        return dedupeKeys(result)
    }
}

/// Parent key level.
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
}

/// Spouse key level
extension RecordIndex {

    /// Return the keys of the spouses of a person key.
    func spouseKeys(ofPersonKey key: RecordKey) -> [RecordKey] {

        let root = requireRoot(from: key, tag: GedcomTag.INDI)
        var result: [RecordKey] = []

        for famsNode in root.kids(withTag: GedcomTag.FAMS) {
            let famsRoot = requireRoot(from: famsNode, tag: GedcomTag.FAM)
            for spouseNode in famsRoot.kids(withTags: [GedcomTag.HUSB, GedcomTag.WIFE]) {
                let spouseRoot = requireRoot(from: spouseNode, tag: GedcomTag.INDI)
                if spouseRoot.key != key {
                    result.append(spouseRoot.key!) // Okay use of !.
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
            result.append(requirePersonKey(on: node))
        }
        return dedupeKeys(result)
    }
}

/// Sibling key level.
extension RecordIndex {

    /// Return the keys of all siblings of the person with given key.
    func siblingKeys(ofPersonKey key: RecordKey) -> [RecordKey] {
        let root = requireRoot(from: key, tag: GedcomTag.INDI)
        var result: [RecordKey] = []

        for famcNode in root.kids(withTag: GedcomTag.FAMC) {
            let famcRoot = requireRoot(from: famcNode, tag: GedcomTag.FAM)
            for childNode in famcRoot.kids(withTag: GedcomTag.CHIL) {
                // childNode is a 1 CHIL node in a FAM record. We want the value of that
                // node to be the key of person record.
                let childKey = requireKeyValue(onNode: childNode)
                if childKey != key {
                    result.append(childKey)
                }
            }
        }
        return dedupeKeys(result)
    }
}

/// Ancestor and descendant key level.
extension RecordIndex {

    /// Return the keys of all ancestors of the person with the given key.
    public func ancestorKeys(ofPersonKey key: RecordKey) -> [RecordKey] {
        let _ = requireRoot(from: key, tag: GedcomTag.INDI)
        var seen = Set<RecordKey>()
        var queue = parentKeys(ofPersonKey: key)
        var next = 0
        var results = [RecordKey]()

        while next < queue.count {
            let key = queue[next]
            next += 1
            if seen.contains(key) { continue }   // Pedigree collapse.
            seen.insert(key)
            results.append(key)
            queue.append(contentsOf: parentKeys(ofPersonKey: key))
        }
        return results
    }

    /// Return the keys of all descendants of the person with the given key.
    public func descendantKeys(ofPersonKey key: RecordKey) -> [RecordKey] {
        let _ = requireRoot(from: key, tag: GedcomTag.INDI)
        var seen = Set<RecordKey>()
        var queue = childrenKeys(ofPersonKey: key)
        var next = 0
        var results = [RecordKey]()

        while next < queue.count {
            let key = queue[next]
            next += 1
            if seen.contains(key) { continue }   // Usually only needed if data is odd.
            seen.insert(key)
            results.append(key)
            queue.append(contentsOf: childrenKeys(ofPersonKey: key))
        }
        return results
    }
}

/// All root level relationship methods.

extension RecordIndex {

    func children(ofPerson root: Root) -> [Root] {

        let perKey = requirePersonKey(on: root)
        return childrenKeys(ofPersonKey: perKey).map {
            requireRoot(from: $0, tag: "INDI")
        }
    }

    func children(ofFamily root: Root) -> [Root] {

        let famKey = requireFamilyKey(on: root)
        return childrenKeys(ofFamilyKey: famKey).map {
            requireRoot(from: $0, tag: GedcomTag.INDI)
        }
    }

    func parents(ofPerson root: Root) -> [Root] {

        let perKey = requirePersonKey(on: root)
        return parentKeys(ofPersonKey: perKey).map {
            requireRoot(from: $0, tag: GedcomTag.INDI)
        }
    }

    func spouses(ofPerson root: Root) -> [Root] {

        let perKey = requirePersonKey(on: root)
        return spouseKeys(ofPersonKey: perKey).map {
            requireRoot(from: $0, tag: GedcomTag.INDI)
        }
    }

    func spouses(ofFamily root: Root) -> [Root] {
        let famKey = requireFamilyKey(on: root)
        return spouseKeys(ofFamilyKey: famKey).map {
            requireRoot(from: $0, tag: GedcomTag.INDI)
        }
    }

    func siblings(ofPerson root: Root) -> [Root] {
        let perKey = requirePersonKey(on: root)
        return siblingKeys(ofPersonKey: perKey).map {
            requireRoot(from: $0, tag: GedcomTag.INDI)
        }
    }
}


extension RecordIndex {

    /// Find the ancestors of a Person from its root GedcomNode.

    public func ancestors(ofPerson root: Root) -> [Root] {

        let startKey = root.requireKey()
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

    /// Find the ancestors of a Person.

    public func ancestors(ofPerson person: Person) -> [Person] {

        let roots = ancestors(ofPerson: person.root)
        return roots.compactMap { $0.key.flatMap { self.person(for: $0) } }
    }

    /// Return the number of ancestors of a Person from its root GedcomNode.

    public func numAncestors(ofPerson root: Root) -> Int {

        return ancestors(ofPerson: root).count
    }

    /// Return the number of ancestors of a Person.

    public func numAncestors(ofPerson person: Person) -> Int {

        ancestors(ofPerson: person.root).count
    }
}

extension RecordIndex {

    /// Find all descendants of a person from its root node.

    public func descendants(ofPerson root: Root) -> [Root] {

        let startKey = root.requireKey()
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

    public func descendants(ofPerson person: Person) -> [Person] {
        let roots = descendants(ofPerson: person.root)
        return roots.compactMap { $0.key.flatMap { self.person(for: $0) } }
    }

    /// Return the number of descendants of a person from its root node.

    public func numDescendants(ofPerson root: Root) -> Int {

        return descendants(ofPerson: root).count
    }

    /// Return the number of descendants of a person.
    ///
    public func numDescendants(ofPerson person: Person) -> Int {
        
        descendants(ofPerson: person.root).count
    }
}

extension RecordIndex {

    /// Require a GedcomNode to have a value that is the key to a Database record
    /// that has a specific type.

    /// TODO: THIS METHOD SHOULD BE MOVED TO A BETTER LOCATION.

    func requireRoot(from node: GedcomNode, tag: Tag) -> Root {

        guard let key = node.val, let root = self[key], root.tag == tag
        else {
            fatalError("expected \(tag) record referenced by \(node)")
        }
        return root
    }

    /// Require a key to map to a Database record, and if a tag is supplied, to
    /// be of that type.

    func requireRoot(from key: RecordKey, tag: Tag? = nil) -> Root {

        guard let root = self[key], root.tag == tag else {
            fatalError("expected root \(key) to refer to a root")
        }
        if tag == nil {
            return root
        }
        guard tag! == root.tag else {
            fatalError("expected root \(root) to have tag \(tag!)")
        }
        return root
    }
}

/// Dedupe the keys in a list while keeping order.
func dedupeKeys(_ keys: [RecordKey]) -> [RecordKey] {
    var seen = Set<RecordKey>()
    return keys.filter { seen.insert($0).inserted }
}

/// Require a node to be a person root node and have a key.
func requirePersonKey(on root: GedcomNode) -> RecordKey {
    return root.requireKey(tag: "INDI")
}

/// Require a node to have a key value.
func requireKeyValue(onNode node: GedcomNode) -> RecordKey {
    guard let key = node.val, key.isKey
    else { fatalError("expected node \(node) to have a key value") }
    return key
}

/// Require a node to be a family root and have a key.
func requireFamilyKey(on root: GedcomNode) -> RecordKey {
    return root.requireKey(tag: "FAM")
}


