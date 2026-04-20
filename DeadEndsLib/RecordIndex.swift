//
//  RecordIndex.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 16 March 2026.
//  Last changed on 28 March 2026.

import Foundation

/// Index of Gedcom records. Wraps a dictionary that maps RecordKeys (Strings) to
/// Roots (GedcomNodes).
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

    /// Create a person record from its root node.
    public func person(for key: String) -> Person? { self[key].flatMap(Person.init) }

    /// Create a family record from its root node.
    public func family(for key: String) -> Family? { self[key].flatMap(Family.init) }
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

    func children(ofPersonRoot root: Root) -> [Root] {
        let perKey = requirePersonKey(on: root)
        return childrenKeys(ofPersonKey: perKey).map {
            requireRoot(from: $0, tag: GedcomTag.INDI)
        }
    }

    func children(ofFamilyRoot root: Root) -> [Root] {
        let famKey = requireFamilyKey(on: root)
        return childrenKeys(ofFamilyKey: famKey).map {
            requireRoot(from: $0, tag: GedcomTag.INDI)
        }
    }

    func parents(ofPersonRoot root: Root) -> [Root] {
        let perKey = requirePersonKey(on: root)
        return parentKeys(ofPersonKey: perKey).map {
            requireRoot(from: $0, tag: GedcomTag.INDI)
        }
    }

    func spouses(ofPersonRoot root: Root) -> [Root] {
        let perKey = requirePersonKey(on: root)
        return spouseKeys(ofPersonKey: perKey).map {
            requireRoot(from: $0, tag: GedcomTag.INDI)
        }
    }

    func spouses(ofFamilyRoot root: Root) -> [Root] {
        let famKey = requireFamilyKey(on: root)
        return spouseKeys(ofFamilyKey: famKey).map {
            requireRoot(from: $0, tag: GedcomTag.INDI)
        }
    }

    func siblings(ofPersonRoot root: Root) -> [Root] {
        let perKey = requirePersonKey(on: root)
        return siblingKeys(ofPersonKey: perKey).map {
            requireRoot(from: $0, tag: GedcomTag.INDI)
        }
    }

    func ancestors(ofPersonRoot root: Root) -> [Root] {
        let perKey = requirePersonKey(on: root)
        return ancestorKeys(ofPersonKey: perKey).map {
            requireRoot(from: $0, tag: GedcomTag.INDI)
        }
    }

    func descendants(ofPersonRoot root: Root) -> [Root] {
        let perKey = requirePersonKey(on: root)
        return descendantKeys(ofPersonKey: perKey).map {
            requireRoot(from: $0, tag: GedcomTag.INDI)
        }
    }
}
