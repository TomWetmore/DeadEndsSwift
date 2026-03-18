//
//  RecordIndex.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 16 March 2026.
//  Last changed on 16 March 2026.

/// In progress. Want to make the RecordIndex a structure so it can have
/// methods. The current state of the software (16 March 2026) has the
/// RecordIndex as a [RecordKey : Root] property of the database.

import Foundation

public struct RecordIndex {
    //var recordIndex: [RecordKey : Root] = [:]

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
