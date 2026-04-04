//
//  Family.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 13 April 2025.
//  Last changed on 2 April 2026.
//

import Foundation

/// Family structure.
public struct Family: Record {

    public let root: Root

    /// Create a family from a 0 FAM node. Fatal error if not possible.
    public init(_ root: Root) {
        guard root.tag == GedcomTag.FAM, root.key != nil
        else { fatalError("Root \(root) is not a valid 0 FAM node") }
        self.root = root
    }
}

/// Extension for husbands, wives and children.
extension Family {

    /// Return all persons with a specific role in this family in Gedcom order.
    private func people(in index: RecordIndex, role: Tag) -> [Person] {
        root.kids(withTag: role).map { node in
            requirePerson(with: index.requireRoot(from: node, tag: GedcomTag.INDI), in: index)
        }
    }

    /// Return all persons with a set of roles in this family in Gedcom order.
    private func people(in index: RecordIndex, roles: Set<Tag>) -> [Person] {
        var seen = Set<RecordKey>()

        return root.kids.compactMap { node in
            guard roles.contains(node.tag) else { return nil }

            let root = index.requireRoot(from: node, tag: GedcomTag.INDI)
            let person = Person(root)
            let key = requireKey(on: root)

            return seen.insert(key).inserted ? person : nil
        }
    }

    /// Return the first husband in this family in Gedcom order.
    public func husband(in index: RecordIndex) -> Person? {
        people(in: index, role: GedcomTag.HUSB).first
    }

    /// Return the first wife in this family in Gedcom order.
    public func wife(in index: RecordIndex) -> Person? {
        people(in: index, role: GedcomTag.WIFE).first
    }

    /// Return all children in this family in Gedcom order.
    public func children(in index: RecordIndex) -> [Person] {
        people(in: index, role: GedcomTag.CHIL)
    }

    /// Return all spouses in the family in Gedcom order; same as parents.
    public func parents(in index: RecordIndex) -> [Person] {
        spouses(in: index)
    }
    
    /// Return all husbands in this family in Gedcom order.
    public func husbands(in index: RecordIndex) -> [Person] {
        people(in: index, role: GedcomTag.HUSB)
    }

    /// Return all wives in this family in Gedcom order.
    public func wives(in index: RecordIndex) -> [Person] {
        people(in: index, role: GedcomTag.WIFE)
    }

    /// Return all spouses in this family in Gedcom order.
    func spouses(in index: RecordIndex) -> [Person] {
        people(in: index, roles: [GedcomTag.HUSB, GedcomTag.WIFE])
    }

    /// Return all spouses except thegiven person in this family in Gedcom order.
    func spouses(excluding person: Person, in index: RecordIndex) -> [Person] {
        spouses(in: index).filter { $0.key != person.key }
    }

    /// Return the first spouse other than the given person in this family.
    public func spouse(of person: Person, in index: RecordIndex) -> Person? {
        spouses(excluding: person, in: index).first
    }

    /// Return true if a person is a spouse in this family.
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

	/// Return the first marriage event in this family.
    public var marriageEvent: Event? {
        root.eventOfKind(.marriage)
    }

    ///Return the first divorce event in this family.
    public var divorceEvent: Event? {
        root.eventOfKind(.divorce)
    }
}
