//
//  Person.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 13 April 2025.
//  Last changed on 30 September 2026.
//

import Foundation

public enum SexType: String {

    case male = "M"
    case female = "F"
    case unknown = "U"
    case undetermined = "X"
}

/// Person structure. A Person is a wrapped INDI root node with methods.
///
public struct Person: Record {

    public let root: Root  // Only stored property.
}

extension Person {

    /// Create a person from a root node. Fatal error if not possible.
    ///
    public init(_ root: Root) {

        guard root.tag == GedcomTag.INDI, root.key != nil else {
            fatalError("Root \(root) is not a valid 0 INDI node")
        }
        self.root = root
    }

    /// Return a Person's key. Fatal error if there is none.
    ///
    public var key: String {

        guard let key = root.key else { fatalError("person must have a key") }
        return key
    }
}

extension Person {

    /// Return a display name for the Person.
    ///
    public var name: String {

        guard let nameNode = root.kid(withTag: GedcomTag.NAME),
              let gedcomName = GedcomName(from: nameNode) else {
            return "no name"
        }
        return gedcomName.displayName()
    }

    /// Return a formatted name string of a person.
    /// TODO: FINISH WRITING THIS METHOD.
    public func formattedName(_: Person, surnameCaps: Bool = false, surnameFirst: Bool = false, maxLength: Int = 68) {
        // Get the Gedcom name
        //let name = GedcomName(from: self)
        let _ = GedcomName(from: self)

    }

    /// Return a single line display summary for this Person.
    ///
    public var displayLine: String {

        let name = displayName()
        let birth = birthEvent?.summary
        let death = deathEvent?.summary

        switch (birth, death) {

        case let (b?, d?): return "\(name) (born \(b) — died \(d))"

        case let (b?, nil): return "\(name) (born \(b))"

        case let (nil, d?): return "\(name) (died \(d))"

        default: return name
        }
    }
}

/// Event operations on a Person.

extension Person {

    /// Return the first birth event of this Person.
    ///
    public var birthEvent: Event? {

        root.eventOfKind(.birth)
    }

    /// Return the first death event of this Person.
    ///
    public var deathEvent: Event? {

        root.eventOfKind(.death)
    }
}

/// Person is Equatable and Hashable.

extension Person: Equatable, Hashable {

    /// Equate two Persons.
    ///
    public static func == (lhs: Person, rhs: Person) -> Bool {

        lhs.root.key == rhs.root.key
    }

    /// Return hash of Person.
    ///
    public func hash(into hasher: inout Hasher) {

        hasher.combine(root.key)
    }
}

public extension Person {

    /// Return sex type person.
    ///
    var sex: SexType {
        
        guard let value = kidVal(forTag: GedcomTag.SEX)?.uppercased() else {
            return .unknown
        }
        switch value {

        case "M": return .male

        case "F": return .female

        default: return .unknown

        }
    }

    /// Return sex symbol of person.
    ///
    var sexSymbol: String {

        switch sex {

        case .male: return "♂️"

        case .female: return "♀️"

        default: return "?"
        }
    }

    /// Return Gedcom name of Person from its first 1 NAME node.
    ///
    var gedcomName: GedcomName? {

        GedcomName(from: self.root)
    }

    /// Return true if the Person is female.
    ///
    var isFemale: Bool { sex == .female }

    /// Return true if the Person is male.
    ///
    var isMale: Bool { return sex == .male }
}

/// Extension for Parents, Mothers, and Fathers.
///
public extension Person {

    /// Return all the Person's parents.
    ///
    func parents(in index: RecordIndex) -> [Person] {

        var result: [Person] = []
        var seen: Set<RecordKey> = []

        for family in childFamilies(in: index) {
            for spouNode in family.kids(withTags: [GedcomTag.HUSB, GedcomTag.WIFE]) {
                let spouRoot = index.requireRoot(from: spouNode, tag: GedcomTag.INDI)
                let parent = requirePerson(from: spouRoot, in: index)
                if seen.insert(parent.root.key!).inserted { result.append(parent) }
            }
        }
        return result
    }

    /// Return the Person's parents of given sex from all spouses in the Person's FAMCs.
    ///
    private func parents(in index: RecordIndex, sex: String) -> [Person] {

        var result: [Person] = []
        var seen: Set<RecordKey> = []

        for family in childFamilies(in: index) {
            for tag in ["HUSB", "WIFE"] {
                for key in family.kidVals(forTag: tag) {
                    guard seen.insert(key).inserted, let parent = index.person(for: key),
                          parent.sex.rawValue == sex
                    else {
                        continue
                    }
                    result.append(parent)
                }
            }
        }
        return result
    }

    /// Return the Person's father from the first male spouse in the Person's FAMCs.
    ///
    func father(in index: RecordIndex) -> Person? {

        parents(in: index, sex: "M").first
    }

    /// Return the Person's mother from the first female spouse in the Person's FAMCs.
    ///
    func mother(in index: RecordIndex) -> Person? {

        parents(in: index, sex: "F").first
    }

    /// Return the Person's fathers from all male spouses in the Person's FAMCs.
    ///
    func fathers(in index: RecordIndex) -> [Person] {

        parents(in: index, sex: "M")
    }

    /// Return the Person's mothers from all female spouses in the Person's FAMCs.
    ///
    func mothers(in index: RecordIndex) -> [Person] {

        parents(in: index, sex: "F")
    }
}

/// Extension for Families.
public extension Person {

    /// Return the families a person is in as a spouse.
    func spouseFamilies(in index: RecordIndex) -> [Family] {

        var families: [Family] = []
        for famsKey in kidVals(forTag: GedcomTag.FAMS) {
            let family = requireFamily(for: famsKey, in: index)
            families.append(family)
        }
        return families
    }

    /// Return the Families a Person is in as a child.

    func childFamilies(in index: RecordIndex) -> [Family] {

        var families: [Family] = []
        for famcKey in kidVals(forTag: GedcomTag.FAMC) {
            let family = requireFamily(for: famcKey, in: index)
            families.append(family)
        }
        return families
    }
}

/// Require a key to refer to a Family. Fatal error if it does not. Return the Family.
///
func requireFamily(for key: RecordKey, in index: RecordIndex) -> Family {

    guard let family = index.family(for: key), family.root.tag == GedcomTag.FAM else {
        fatalError("key \(key) must refer to a family")
    }
    return family
}

/// Require a key to refer to a Person. Fatal error if it does not. Return the Person.
///
public func requirePerson(with key: RecordKey, in index: RecordIndex) -> Person {

    guard let person = index.person(for: key), person.root.tag == "INDI" else {
        fatalError("key \(key) must refer to a person")
    }
    return person
}

/// Require a GedcomNode to be the root of a Person. Fatal error if it does not.
/// Return the Person.
///
public func requirePerson(from root: Root, in index: RecordIndex) -> Person {

    let key = root.requireKey(tag: "INDI")
    guard let person = index.person(for: key), person.root.tag == "INDI" else {
        fatalError("root \(root) must be the root of a person")
    }
    return person
}

/// Extension for spouses, husbands, and wives.
///
public extension Person {

    /// Return the first spouse of a Person by role. There is no restriction on the sex
    /// of the spouse.

    func spouse(in index: RecordIndex, roles: [Tag]) -> Person? {

        for family in spouseFamilies(in: index) {
            for role in roles {
                for key in family.kidVals(forTag: role) where key != self.key {
                    if let spouse = index.person(for: key) {
                        return spouse
                    }
                }
            }
        }
        return nil
    }

    /// Return the first husband of a Person. The Person can be male or female.
    ///
    func husband(in index: RecordIndex) -> Person? {

        spouse(in: index, roles: [GedcomTag.HUSB])
    }

    /// Return the first wife of a Person. The Person can be male or female.
    ///
    func wife(in index: RecordIndex) -> Person? {

        spouse(in: index, roles: [GedcomTag.WIFE])
    }

    /// Return all spouses of a Person, filtered by roles, deduped, in Gedcom order.
    ///
    func spouses(in index: RecordIndex,
                 roles: [Tag] = [GedcomTag.HUSB,GedcomTag.WIFE]) -> [Person] {

        var seen = Set<RecordKey>()
        var out: [Person] = []

        for family in spouseFamilies(in: index) {
            for role in roles {
                for key in family.kidVals(forTag: role)
                where key != self.key && seen.insert(key).inserted {
                    if let spouse = index.person(for: key) { out.append(spouse) }
                }
            }
        }
        return out
    }

    /// Return all unique (spouse, Family) pairs for a Person. This was written to support
    /// the forspouses statement in the programming language.

//    func spousesWithFamilies(in index: RecordIndex) -> [(spouse: Person, family: Family)] {
//
//        var seen = Set<String>()
//        var results = [(spouse: Person, family: Family)]()
//
//        for family in spouseFamilies(in: index) {
//            for spouse in family.spouses(excluding: self, in: index) {
//                let pairKey = "\(spouse.key)|\(family.key)"
//                if seen.insert(pairKey).inserted {
//                    results.append((spouse, family))
//                }
//            }
//        }
//        return results
//    }

    /// Return all husbands of person, deduped and in order; person can be male or female.
    func husbands(in index: RecordIndex) -> [Person] {

        spouses(in: index, roles: [GedcomTag.HUSB])
    }

    /// Return all wives of person, deduped and in order; person can be male or female.
    func wives(in index: RecordIndex) -> [Person] {

        spouses(in: index, roles: [GedcomTag.WIFE])
    }
}

/// Extension for Siblings.

extension Person {

    /// Return a Person's siblings from all its FAMC families, deduped and in Gedcom order.

    public func siblings(in index: RecordIndex) -> [Person] {

        var seen: Set<RecordKey> = []
        var result: [Person] = []

        for family in childFamilies(in: index) {
            for child in family.children(in: index) where child.key != self.key {
                if seen.insert(child.key).inserted {
                    result.append(child)
                }
            }
        }
        return result
    }

    public func brothers(in index: RecordIndex) -> [Person] {
        var seen: Set<RecordKey> = []
        var result: [Person] = []

        for family in childFamilies(in: index) {
            for child in family.children(in: index) where child.key != self.key && child.isMale {
                if seen.insert(child.key).inserted {
                    result.append(child)
                }
            }
        }
        return result
    }

    public func sisters(in index: RecordIndex) -> [Person] {
        var seen: Set<RecordKey> = []
        var result: [Person] = []

        for family in childFamilies(in: index) {
            for child in family.children(in: index) where child.key != self.key && child.isFemale {
                if seen.insert(child.key).inserted {
                    result.append(child)
                }
            }
        }
        return result
    }

    /// Return person's previous sibling in person's first FAMC.
    ///
    public func previousSibling(in index: RecordIndex) -> Person? {

        guard let family = self.childFamilies(in: index).first else { return nil }
        let children = family.children(in: index)
        guard let indexOfSelf = children.firstIndex(of: self),
              indexOfSelf < children.count - 1 else { return nil }
        return children[indexOfSelf + 1]
    }

    /// Return person's next sibling in person's first FAMC.
    ///
    public func nextSibling(in index: RecordIndex) -> Person? {

        guard let family = self.childFamilies(in: index).first else { return nil }
        let children = family.children(in: index)
        guard let indexOfSelf = children.firstIndex(of: self),
              indexOfSelf > 0 else { return nil }
        return children[indexOfSelf - 1]
    }
}

public extension Person {

    /// Return children of self, from all FAMS families, deduped in Gedcom order.
    ///
    func children(in index: RecordIndex) -> [Person] {

        var seen: Set<RecordKey> = []
        var result: [Person] = []

        for family in spouseFamilies(in: index) {
            for child in family.children(in: index) {
                if seen.insert(child.key).inserted {
                    result.append(child)
                }
            }
        }
        return result
    }

    /// Return the sons of a Person as an array of Persons.
    ///
    func sons(in index: RecordIndex) -> [Person] {

        var seen: Set<RecordKey> = []
        var result: [Person] = []

        for family in spouseFamilies(in: index) {
            for child in family.children(in: index) {
                if child.isMale && seen.insert(child.key).inserted {
                    result.append(child)
                }
            }
        }
        return result
    }

    /// Return the daughters of a Person as as array of Persons.
    ///
    func daughters(in index: RecordIndex) -> [Person] {

        var seen: Set<RecordKey> = []
        var result: [Person] = []

        for family in spouseFamilies(in: index) {
            for child in family.children(in: index) {
                if child.isFemale && seen.insert(child.key).inserted {
                    result.append(child)
                }
            }
        }
        return result
    }
}

/// Extension for ancestors and descendants.

public extension Person {

    /// Return the ancestors of a Person as an array of Persons.
    ///
    func ancestors(in index: RecordIndex) -> [Person] {

        index.ancestors(ofPerson: root).map { ancestorRoot in
            Person(ancestorRoot)
        }
    }

    /// Return the descendants of a Person as an array of Persons.
    ///
    func descendants(in index: RecordIndex) -> [Person] {

        index.descendants(ofPerson: root).map { descendantRoot in
            Person(descendantRoot)
        }
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

    /// Compare Persons by name presence, name, birth year, death year, and record key.
    ///
    public func compare(to other: Person) -> ComparisonResult {

        let nameOne = GedcomName(from: root)
        let nameTwo = GedcomName(from: other.root)

        switch (nameOne, nameTwo) {

        case let (nameOne?, nameTwo?):
            let relation = nameOne.compare(to: nameTwo)
            if relation != .orderedSame {
                return relation
            }

        case (_?, nil):
            // Named persons sort before unnamed persons.
            return .orderedAscending

        case (nil, _?):
            return .orderedDescending

        case (nil, nil):
            // Continue with birth, death, and key.
            break
        }
        let birthOne = birthEvent?.year
        let birthTwo = other.birthEvent?.year
        if let relation = compareOptionalInts(birthOne, birthTwo),
           relation != .orderedSame {
            return relation
        }
        let deathOne = deathEvent?.year
        let deathTwo = other.deathEvent?.year
        if let relation = compareOptionalInts(deathOne, deathTwo),
           relation != .orderedSame {
            return relation
        }
        if key == other.key { return .orderedSame }
        return key < other.key ? .orderedAscending : .orderedDescending
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
