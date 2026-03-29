//
//  Family.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 13 April 2025.
//  Last changed on 28 March 2026.
//

import Foundation

/// Family structure.
public struct Family: Record {

    public let root: Root

    /// Create family from a 0 FAM node. Fatal error if not possible.
    public init(_ root: Root) {
        guard root.tag == GedcomTag.FAM, root.key != nil
        else { fatalError("Root \(root) is not a valid 0 FAM node") }
        self.root = root
    }
}

/// Extension for husbands, wives and children.
extension Family {

    /// Return all persons with a specific role in the family in Gedcom order.
    private func oldpeople(in index: RecordIndex, role: String) -> [Person] {
        root.kids(withTag: role).compactMap { node in
            node.val.flatMap { index.person(for: $0) }
        }
    }

    /// Get all persons from a family who have a specific role.
    private func people(in index: RecordIndex, role: Tag) -> [Person] {
        var result: [Person] = []
        
        let nodes = root.kids(withTag: role)
        for node in nodes { // HUSB, WIFE, or CHIL nodes.
            let roleRoot = index.requireRoot(from: node, tag: GedcomTag.INDI)
            result.append(requirePerson(with: roleRoot, in: index))
        }
        return result
    }

    /// Return all persons with a set of roles in the family in Gedcom order.
    private func people(in index: RecordIndex, roles: Set<String>) -> [Person] {

        var out: [Person] = []
        var seen = Set<RecordKey>()

        for node in root.kids {
            guard roles.contains(where: { $0 == node.tag }) else { continue }
            guard let key = node.val else { continue }
            guard seen.insert(key).inserted else { continue }
            if let person = index.person(for: key) { out.append(person) }
        }
        return out
    }

    /// Return first husband in the family in Gedcom order.
    public func husband(in index: RecordIndex) -> Person? {
        people(in: index, role: GedcomTag.HUSB).first
    }

    /// Return first wife of the family in Gedcom order.
    public func wife(in index: RecordIndex) -> Person? {
        people(in: index, role: GedcomTag.WIFE).first
    }

    /// Return all children of the family in Gedcom order.
    public func children(in index: RecordIndex) -> [Person] {
        people(in: index, role: GedcomTag.CHIL)
    }

    /// Return all spouses in the family; same as parents.
    public func parents(in index: RecordIndex) -> [Person] {
        spouses(in: index)
    }
    
    /// Return all husbands of the family in Gedcom order.
    public func husbands(in index: RecordIndex) -> [Person] {
        people(in: index, role: GedcomTag.HUSB)
    }

    /// Return all wives of the family in Gedcom order.
    public func wives(in index: RecordIndex) -> [Person] {
        people(in: index, role: GedcomTag.WIFE)
    }

    /// Return all spouses in the family in Gedcom order.
    func spouses(in index: RecordIndex) -> [Person] {
        people(in: index, roles: [GedcomTag.HUSB, GedcomTag.WIFE])
    }

    /// Return all spouses except given person in the family in Gedcom order.
    func spouses(excluding person: Person, in index: RecordIndex) -> [Person] {
        spouses(in: index).filter { $0.key != person.key }
    }

    /// Return first spouse other than given person in the family.
    public func spouse(of person: Person, in index: RecordIndex) -> Person? {
        spouses(excluding: person, in: index).first
    }

    /// Return true if person is a spouse in the family.
    func hasSpouse(_ person: Person, in index: RecordIndex) -> Bool {
        spouses(in: index).contains(where: { $0.key == person.key })
    }
}

/// Extension to meet protocols
extension Family: Equatable, Hashable, Identifiable {

    public static func == (lhs: Family, rhs: Family) -> Bool {
        lhs.root.key == rhs.root.key
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(root.key)
    }

    public var id: String { key }
}

extension Family {

	/// Return first marriage event in the family.
    public var marriageEvent: Event? {
        root.eventOfKind(.marriage)
    }

    public var divorceEvent: Event? {
        root.eventOfKind(.divorce)
    }
}
