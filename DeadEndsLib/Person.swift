//
//  Person.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 13 April 2025.
//  Last changed on 18 February 2026.
//

import Foundation

public enum FamilyRoleTag: String {
    case husband = "HUSB"
    case wife    = "WIFE"
    case child   = "CHIL"
}

public enum ParentRoleTag: String {
    case husband = "HUSB"
    case wife    = "WIFE"
}

public enum FamilyLinkTag: String {
    case fams = "FAMS"
    case famc = "FAMC"
}

public enum SexType: String {
    case male = "M"
    case female = "F"
    case unknown = "U"
}

/// Person structure.
public struct Person: Record {

    public let root: GedcomNode

    /// Create person. Fail if root is not INDI or has no key.
    public init?(_ root: GedcomNode) {
        guard root.tag == GedcomTag.INDI, root.key != nil
        else { return nil }
        self.root = root
    }
}

extension Person {

    /// Return display name from the first 1 NAME node.
    public var name: String? {
        guard let nameNode = root.kid(withTag: GedcomTag.NAME),
              let gedcomName = GedcomName(from: nameNode)
        else { return nil }
        return gedcomName.displayName()
    }
}

/// Event API.
extension Person {

    /// Return first birth event.
    public var birthEvent: Event? {
        root.eventOfKind(.birth)
    }

    /// Return first death event.
    public var deathEvent: Event? {
        root.eventOfKind(.death)
    }
}

/// Person is Equatable and Hashable.
extension Person: Equatable, Hashable {

    /// Equate two persons.
    public static func == (lhs: Person, rhs: Person) -> Bool {
        lhs.root.key == rhs.root.key
    }

    /// Return person hash.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(root.key)
    }
}

public extension Person {

    /// Return sex type person.
    var sex: SexType {
        guard let value = kidVal(forTag: GedcomTag.SEX)?.uppercased()
        else { return .unknown }
        switch value {
        case "M": return .male
        case "F": return .female
        default: return .unknown
        }
    }

    /// Return sex symbol of person.
    var sexSymbol: String {
        switch sex {
        case .male: return "♂️"
        case .female: return "♀️"
        default: return "?"
        }
    }

    /// Return Gedcom name of person from its first 1 NAME node.
    var gedcomName: GedcomName? {
        GedcomName(from: self.root)
    }

    /// Return true if person is female.
    var isFemale: Bool { sex == .female }

    /// Return true if person is male.
    var isMale: Bool { return sex == .male }
}

/// Extension for Parents, Mothers, and Fathers.
public extension Person {

    /// Return person's parents.
    private func parents(in index: RecordIndex, role: ParentRoleTag) -> [Person] {
        var result: [Person] = []
        var seen: Set<RecordKey> = []

        for family in childFamilies(in: index) {
            for key in family.kidVals(forTag: role.rawValue) {
                guard seen.insert(key).inserted,
                      let parent = index.person(for: key)
                else { continue }
                result.append(parent)
            }
        }
        return result
    }

    /// Return person's father from first husband in person's first FAMC with a husband.
    func father(in index: RecordIndex) -> Person? { parents(in: index, role: .husband).first }

    /// Return person's mother by finding first wife in person's first FAMC with a wife.
    func mother(in index: RecordIndex) -> Person? { parents(in: index, role: .wife).first }

    /// Return all person's fathers by finding all husbands in all person's FAMC families.
    func fathers(in index: RecordIndex) -> [Person] { parents(in: index, role: .husband) }

    /// Return all person's mothers by finding all wives in all person's FAMC families.
    func mothers(in index: RecordIndex) -> [Person] { parents(in: index, role: .wife) }
}

/// Extension for Families.
public extension Person {

    /// Return families person is a spouse in.
    func spouseFamilies(in index: RecordIndex) -> [Family] {
        var families: [Family] = []
        for famsKey in kidVals(forTag: FamilyLinkTag.fams.rawValue) {
            guard let family = index.family(for: famsKey)
            else { continue }
            families.append(family)
        }
        return families
    }

    /// Return families person is a child in.
    func childFamilies(in index: RecordIndex) -> [Family] {
        var families: [Family] = []
        for famcKey in kidVals(forTag: FamilyLinkTag.famc.rawValue) {
            guard let family = index.family(for: famcKey)
            else { continue }
            families.append(family)
        }
        return families
    }
}

/// Extension for Spouses, Husbands, and Wives
public extension Person {

    /// Return first spouse of self by role; is no restriction on sex of spouse.
    func spouse(in index: RecordIndex, roles: [FamilyRoleTag]) -> Person? {
        for family in spouseFamilies(in: index) {
            for role in roles {
                for key in family.kidVals(forTag: role.rawValue) where key != self.key {
                    if let spouse = index.person(for: key) { return spouse }
                }
            }
        }
        return nil
    }

    /// Return first husband of person; person can be male or female.
    func husband(in index: RecordIndex) -> Person? {
        spouse(in: index, roles: [.husband])
    }

    /// Return first wife of person; person can be male or female.
    func wife(in index: RecordIndex) -> Person? {
        spouse(in: index, roles: [.wife])
    }

    /// Return all spouses of person, filtered by roles, deduped, in Gedcom order.
    func spouses(in index: RecordIndex, roles: [FamilyRoleTag] = [.husband, .wife]) -> [Person] {

        var seen = Set<RecordKey>()
        var out: [Person] = []

        for family in spouseFamilies(in: index) {
            for role in roles {
                for key in family.kidVals(forTag: role.rawValue)
                where key != self.key && seen.insert(key).inserted {
                    if let spouse = index.person(for: key) { out.append(spouse) }
                }
            }
        }
        return out
    }

    /// Return all husbands of person, deduped and in order; person can be male or female.
    func husbands(in index: RecordIndex) -> [Person] {
        spouses(in: index, roles: [.husband])
    }

    /// Return all wives of person, deduped and in order; person can be male or female.
    func wives(in index: RecordIndex) -> [Person] {
        spouses(in: index, roles: [.wife])
    }
}

/// Extension for Siblings.
extension Person {

    /// Return person's siblings from all FAMC families, deduped and in gedcom order.
    public func siblings(in index: RecordIndex) -> [Person] {

        var seen: Set<RecordKey> = []
        var result: [Person] = []

        for family in childFamilies(in: index) {
            for child in family.children(in: index) where child.key != self.key {
                if seen.insert(child.key).inserted { result.append(child) }
            }
        }
        return result
    }

    /// Return person's previous sibling in person's first FAMC.
    public func previousSibling(in index: RecordIndex) -> Person? {

        guard let family = self.childFamilies(in: index).first else { return nil }
        let children = family.children(in: index)
        guard let indexOfSelf = children.firstIndex(of: self),
              indexOfSelf < children.count - 1 else { return nil }
        return children[indexOfSelf + 1]
    }

    // Return person's next sibling in person's first FAMC.
    public func nextSibling(in index: RecordIndex) -> Person? {

        guard let family = self.childFamilies(in: index).first else { return nil }
        let children = family.children(in: index)
        guard let indexOfSelf = children.firstIndex(of: self),
              indexOfSelf > 0 else { return nil }
        return children[indexOfSelf - 1]
    }
}

public extension Person {

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
}

extension Database {

    enum PersonUpdateError: Swift.Error {

        case missingName
        case inconsistentSex
        case invalidLinks
        // ... add others as you refine rules
    }

    public func updatePerson(_ person: Person) {
        recordIndex[person.key] = person.root
    }
}

extension Person {

    /// Compare persons by name, birth year, death year, and record key.
    func compare(to other: Person, in index: RecordIndex) -> ComparisonResult {

        if let nameOne = GedcomName(from: self.root), let nameTwo = GedcomName(from: other.root) {
            let relation = nameOne.compare(to: nameTwo)
            if relation != .orderedSame { return relation }
        }
        let birthOne = self.birthEvent?.year
        let birthTwo = other.birthEvent?.year
        if let relation = compareOptionalInts(birthOne, birthTwo), relation != .orderedSame { return relation }

        let deathOne = self.deathEvent?.year
        let deathTwo = other.deathEvent?.year
        if let relation = compareOptionalInts(deathOne, deathTwo), relation != .orderedSame { return relation }

        if self.key == other.key { return .orderedSame }
        return self.key < other.key ? .orderedAscending : .orderedDescending
    }
}

/// Compare optional integers.
private func compareOptionalInts(_ a: Int?, _ b: Int?) -> ComparisonResult? {
    switch (a, b) {
    case let (x?, y?) where x != y:
        return x < y ? .orderedAscending : .orderedDescending
    case (.some, .none):
        return .orderedAscending
    case (.none, .some):
        return .orderedDescending
    default:
        return .orderedSame
    }
}
