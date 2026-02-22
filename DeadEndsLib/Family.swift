//
//  Family.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 13 April 2025.
//  Last changed on 19 February 2026.
//

import Foundation

extension FamilyRoleTag {
    static let HUSB = FamilyRoleTag.husband.rawValue
    static let WIFE = FamilyRoleTag.wife.rawValue
    static let CHIL = FamilyRoleTag.child.rawValue
}

/// Family structure.
public struct Family: Record {

    public let root: GedcomNode

    /// Create family from a 0 FAM node; fail if tag not FAM or no key.
    public init?(_ root: GedcomNode) {
        guard root.tag == "FAM", root.key != nil  else { return nil }
        self.root = root
    }
}

/// Extension for husbands, wives and children.
extension Family {

    /// Return all persons with a specific role in the family in Gedcom order.
    private func people(in index: RecordIndex, role: FamilyRoleTag) -> [Person] {
        root.kids(withTag: role.rawValue).compactMap { node in
            node.val.flatMap { index.person(for: $0) }
        }
    }

    /// Return all persons with a set of roles in the family in Gedcom order.
    private func people(in index: RecordIndex, roles: Set<FamilyRoleTag>) -> [Person] {

        var out: [Person] = []
        var seen = Set<RecordKey>()

        for node in root.kids {
            guard roles.contains(where: { $0.rawValue == node.tag }) else { continue }
            guard let key = node.val else { continue }
            guard seen.insert(key).inserted else { continue }
            if let person = index.person(for: key) { out.append(person) }
        }
        return out
    }

    /// Return first husband in the family in Gedcom order.
    public func husband(in index: RecordIndex) -> Person? {
        people(in: index, role: .husband).first
    }

    /// Return first wife of the family in Gedcom order.
    public func wife(in index: RecordIndex) -> Person? {
        people(in: index, role: .wife).first
    }

    /// Return all children of the family in Gedcom order.
    public func children(in index: RecordIndex) -> [Person] {
        people(in: index, role: .child)
    }

    /// Return all spouses in the family; same as parents.
    public func parents(in index: RecordIndex) -> [Person] {
        spouses(in: index)
    }
    
    /// Return all husbands of the family in Gedcom order.
    public func husbands(in index: RecordIndex) -> [Person] {
        people(in: index, role: .husband)
    }

    /// Return all wives of the family in Gedcom order.
    public func wives(in index: RecordIndex) -> [Person] {
        people(in: index, role: .wife)
    }

    /// Return all spouses in the family in Gedcom order.
    func spouses(in index: RecordIndex) -> [Person] {
        people(in: index, roles: [.husband, .wife])
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
