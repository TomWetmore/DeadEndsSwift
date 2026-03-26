//
//  RecordIndex.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 16 March 2026.
//  Last changed on 24 March 2026.

import Foundation

public struct RecordIndex {

    private var table: [RecordKey: Root] = [:]  // Representation.

    public init() {}

    public init(_ table: [RecordKey: Root]) {
        self.table = table
    }

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

    /// Create person from root.
    public func person(for key: String) -> Person? { self[key].flatMap(Person.init) }

    /// Create family from root.
    public func family(for key: String) -> Family? { self[key].flatMap(Family.init) }
}

extension RecordIndex {

    /// Return all persons with a set of roles in the family in Gedcom order.
    private func people(in family: Family, roles: Set<FamilyRoleTag>) -> [Person] {
        var out: [Person] = []
        var seen = Set<RecordKey>()

        for node in family.root.kids {
            guard roles.contains(where: { $0.rawValue == node.tag }) else { continue }
            guard let key = node.val else { continue }
            guard seen.insert(key).inserted else { continue }
            if let person = person(for: key) { out.append(person) }
        }
        return out
    }
}

/// Bottom of the relationships ladder.

extension RecordIndex {

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

    /// Return the keys of the children of a family key.
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

    func children(ofPersonRoot root: Root) -> [Root] {
        guard root.tag == GedcomTag.INDI, let perKey = root.key
        else { fatalError("person root \(root) is not a person or has no key") }
        return childrenKeys(ofPersonKey: perKey).compactMap{ self[$0] }
    }

    func children(ofFamilyRoot root: Root) -> [Root] {
        guard root.tag == GedcomTag.FAM, let famKey = root.key
        else { fatalError("family root \(root) is not a family or has no key") }
        return childrenKeys(ofFamilyKey: famKey).compactMap { self[$0] }
    }
    /*
     /// Return children of self, in all FAMS families, deduped in Gedcom order.
     func children(in index: RecordIndex) -> [Person] {
         var seen: Set<RecordKey> = []
         var result: [Person] = []

         for family in spouseFamilies(in: index) {
             for child in family.children(in: index) {
                 if seen.insert(child.key).inserted { result.append(child) }
             }
         }
         return result
     }
     */
//    children(of person: Person) -> PersonSet
//    children(of family: Family) -> PersonSet
//
//    children(ofPersonRoot root: Root) -> PersonSet
//    children(ofFamilyRoot root: Root) -> PersonSet

//    func parentKeys(ofPersonKey key: RecordKey) -> Set<RecordKey> {
//        var results = Set<RecordKey>()
//        return results
//    }

    func spouseKeys(of: RecordKey) -> Set<RecordKey> {
        var results: Set<RecordKey> = []
        return results
    }
}
