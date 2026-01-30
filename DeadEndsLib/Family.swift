//
//  Family.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 13 April 2025.
//  Last changed on 14 January 2026.
//

import Foundation

extension FamilyRoleTag {
    static let HUSB = FamilyRoleTag.husband.rawValue
    static let WIFE = FamilyRoleTag.wife.rawValue
    static let CHIL = FamilyRoleTag.child.rawValue
}

/// Structure holding a family.
public struct Family: Record {

    public let root: GedcomNode

    /// Init a new family from a 0 FAM node.
    public init?(_ root: GedcomNode) {
        guard root.tag == "FAM", root.key != nil  else { return nil }
        self.root = root
    }
}

/// Extension for husbands, wives and children.
extension Family {

    /// Return array of all persons in a role with self in gedcom order.
    private func people(in index: RecordIndex, role: FamilyRoleTag) -> [Person] {
        root.kids(withTag: role.rawValue).compactMap { node in
            node.val.flatMap { index.person(for: $0) }
        }
    }

    /// Return array of all persons with a set of roles with self in gedcom order.
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

    /// Return first husband of self in gedcom order.
    public func husband(in index: RecordIndex) -> Person? {
        people(in: index, role: .husband).first
    }

    /// Return first wife of self in gedcom order.
    public func wife(in index: RecordIndex) -> Person? {
        people(in: index, role: .wife).first
    }

    /// Return all children of self in gedcom order.
    public func children(in index: RecordIndex) -> [Person] {
        people(in: index, role: .child)
    }

    public func parents(in index: RecordIndex) -> [Person] {
        spouses(in: index)
    }
    
    /// Return all husbands of self in gedcom order.
    public func husbands(in index: RecordIndex) -> [Person] {
        people(in: index, role: .husband)
    }

    /// Return all wives of self in gedcom order.
    public func wives(in index: RecordIndex) -> [Person] {
        people(in: index, role: .wife)
    }
}

public extension Family {

    /// Return all spouses in self in gedcom order.
    func spouses(in index: RecordIndex) -> [Person] {
        people(in: index, roles: [.husband, .wife])
    }

    /// Return all spouses except given person in self in gedcom order.
    func spouses(excluding person: Person, in index: RecordIndex) -> [Person] {
        spouses(in: index).filter { $0.key != person.key }
    }

    /// Return first spouse other than given person in self.
    func spouse(of person: Person, in index: RecordIndex) -> Person? {
        spouses(excluding: person, in: index).first
    }

    /// Return true if person is a spouse in self.
    func containsSpouse(_ person: Person, in index: RecordIndex) -> Bool {
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
