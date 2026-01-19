//
//  Person.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 13 April 2025.
//  Last changed on 13 January 2026.
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

/// Type of  Person Record.
public struct Person: Record {

    public let root: GedcomNode  // Protocol requirement.

    /// Initializer fails if root's tag is not "INDI" or root has no key.
    public init?(_ root: GedcomNode) {
        guard root.tag == "INDI", root.key != nil
        else { return nil }
        self.root = root
    }
}

extension Person {

    /// Return self's name from the first 1 NAME node.
    public var name: String? {

        guard let nameNode = root.kid(withTag: "NAME"),
              let gedcomName = GedcomName(from: nameNode)
        else { return nil }
        return gedcomName.displayName()
    }

    /// Return self's birth event from its first 1 BIRT node.
    public var birth: GedcomNode? {
        return root.kid(withTag: "BIRT")
    }

    /// Return self's death event from its first 1 DEAT node.
    public var death: GedcomNode? {
        return root.kid(withTag: "DEAT")
    }
}

/// Persons are Equatable and Hashable.
extension Person: Equatable, Hashable {

    public static func == (lhs: Person, rhs: Person) -> Bool {
        lhs.root.key == rhs.root.key
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(root.key)
    }
}

/// Enumeration for sex values.
public enum SexType: String {
    case male = "M"
    case female = "F"
    case unknown = "U"
}

public extension Person {

    /// Return sex of self.
    var sex: SexType {

        guard let value = kidVal(forTag: "SEX")?.uppercased()
        else { return .unknown }
        switch value {
        case "M": return .male
        case "F": return .female
        default: return .unknown
        }
    }

    // Return sex symbol (Mars or Venus) of self.
    var sexSymbol: String {
        switch sex {
        case .male: return "♂️"
        case .female: return "♀️"
        default: return "?"
        }
    }

    // Return self's GedcomName from the value of the first 1 NAME node.
    var gedcomName: GedcomName? {
        GedcomName(from: self.root)
    }

    /// Return true self is female.
    var isFemale: Bool { sex == .female }

    /// Return true if self is male.
    var isMale: Bool { return sex == .male }
}

/// Extension for Parents, Mothers, and Fathers.
public extension Person {

    /// Return self's parents.
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

    /// Return self's father by finding the first husband in self's first FAMC with one.
    func father(in index: RecordIndex) -> Person? { parents(in: index, role: .husband).first }

    /// Return self's mother by finding the first wife in self's first FAMC with one.
    func mother(in index: RecordIndex) -> Person? { parents(in: index, role: .wife).first }

    /// Return all self's fathers by finding all husbands in all self's FAMC families.
    func fathers(in index: RecordIndex) -> [Person] { parents(in: index, role: .husband) }

    /// Return all self's mothers by finding all wives in all self's FAMC families.
    func mothers(in index: RecordIndex) -> [Person] { parents(in: index, role: .wife) }
}

/// Extension for Families.
public extension Person {

    /// Return the families self is a spouse in.
    func spouseFamilies(in index: RecordIndex) -> [Family] {

        var families: [Family] = []
        for famsKey in kidVals(forTag: FamilyLinkTag.fams.rawValue) {
            guard let family = index.family(for:famsKey)
            else { continue }
            families.append(family)
        }
        return families
    }

    /// Return the families self is a child in.
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

    /// Return first spouse of self by role. There is no restriction on the sex of spouse.
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

    /// Return the first husband of self. Self can be male or female.
    func husband(in index: RecordIndex) -> Person? {
        spouse(in: index, roles: [.husband])
    }

    /// Return the first wife of self. Self can be male or femaile.
    func wife(in index: RecordIndex) -> Person? {
        spouse(in: index, roles: [.wife])
    }

    /// Return all spouses of self, filtered by roles, deduped, in gedcom order.
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

    /// Return all husbands of self, deduped and in order; self can be male or female.
    func husbands(in index: RecordIndex) -> [Person] {
        spouses(in: index, roles: [.husband])
    }

    /// Return all wives of self, deduped and in order; self can be male or female.
    func wives(in index: RecordIndex) -> [Person] {
        spouses(in: index, roles: [.wife])
    }
}

/// Extension for Siblings.
extension Person {

    /// Return self's siblings from all self's FAMC families, deduped and in gedcom order.
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

    /// Return self's previous sibling in self's first FAMC.
    public func previousSibling(in index: RecordIndex) -> Person? {

        guard let family = self.childFamilies(in: index).first else { return nil }
        let children = family.children(in: index)
        guard let indexOfSelf = children.firstIndex(of: self),
              indexOfSelf < children.count - 1 else { return nil }
        return children[indexOfSelf + 1]
    }

    // Return self's next sibling in self's first FAMC.
    public func nextSibling(in index: RecordIndex) -> Person? {

        guard let family = self.childFamilies(in: index).first else { return nil }
        let children = family.children(in: index)
        guard let indexOfSelf = children.firstIndex(of: self),
              indexOfSelf > 0 else { return nil }
        return children[indexOfSelf - 1]
    }
}

public extension Person {

    /// Return all children of self; deduped and in gedcom order.
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
        //        // 1. Validate
        //        guard !person.kidVals(forTag: "NAME").isEmpty else {
        //            throw PersonUpdateError.missingName
        //        }
        //        if let sex = person.sex {
        //            try validateSexConsistency(person, sex: sex)
        //        }
        //
        //        // 2. Canonicalize (placeholder for now)
        //        let canonical = canonicalize(person)
        //
        //        // 3. Maintain indexes
        //        updateIndexesForPerson(canonical)
        //
        //        // 4. History / undo
        //        recordDelta(.personUpdated(canonical))
        //
        //        // 5. Commit
        //recordIndex[canonical.key] = canonical.root
        recordIndex[person.key] = person.root
    }
}

public func showPersons(_ persons: [Person]) {
    for person in persons {
        guard let name = person.name else { print("no name"); continue }
        print(name)
    }
}
