//
//  Person.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 13 April 2025.
//  Last changed on 20 September 2025.
//

import Foundation

/// Type of  Person Record.
public struct Person: Record {

    public let root: GedcomNode  // Root GedcomNode; protocol requirement.

    /// Person initializer fails if root's tag is not "INDI" and/or root has no key. This guarantees that every
    /// Person has a non-optional key.
    public init?(_ root: GedcomNode) {
        guard root.tag == "INDI", root.key != nil else { return nil }
        self.root = root
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
public enum SexType {
    case male
    case female
    case unknown
}

public extension Person {

    /// Returns sex of Person.
    var sex: SexType {
        guard let value = kidVal(forTag: "SEX")?.uppercased() else { return .unknown }
        switch value {
        case "M": return .male
        case "F": return .female
        default: return .unknown
        }
    }

    // Returns sex symbol (Mars or Venus) of Person.
    var sexSymbol: String {
        switch sex {
        case .male: return "♂️"
        case .female: return "♀️"
        default: return "?"
        }
    }

    // Returns a GedcomName object for Person.
    var gedcomName: GedcomName? {
        GedcomName(from: self.root)
    }

    /// Returns true if a Person is female.
    var isFemale: Bool { sex == .female }

    /// Returns true if a Person is male.
    var isMale: Bool { return sex == .male }

    /// Returns the father of a Person. Finds the first husband in the first family-as-child that has one.
    func father(in index: RecordIndex) -> Person? {
        for famcKey in self.root.kidVals(forTag: "FAMC") {
            guard let family = index.family(for: famcKey), let husbKey = family.kidVal(forTag: "HUSB"),
                  let father = index.person(for: husbKey) else { continue }
            return father
        }
        return nil
    }

    /// Returns all fathers of a Person. Finds all husbands in all families as child the Person is in.
    func fathers(in index: RecordIndex) -> [Person] {
        var result: [Person] = []
        var seenKeys: Set<String> = []

        for famc in self.root.kids(withTag: "FAMC") {
            guard let famKey = famc.val,
                  let family = index.family(for: famKey) else { continue } // Can't happen.
            for husb in family.kids(withTag: "HUSB") {
                guard let husbKey = husb.val, !seenKeys.contains(husbKey),
                      let father = index.person(for: husbKey) else { continue } // Can't happen.
                result.append(father)
                seenKeys.insert(husbKey)
            }
        }
        return result
    }

    /// Returns the mother a Person. Finds the first mother in the first family-as-child that has one.
    func mother(in index: RecordIndex) -> Person? {
        for famcKey in self.kidVals(forTag: "FAMC") {
            guard let family = index.family(for: famcKey), let wifeKey = family.kidVal(forTag: "WIFE"),
                  let mother = index.person(for: wifeKey) else {
                continue
            }
            return mother
        }
        return nil
    }

    /// Returns all mothers of a Person.
    func mothers(in index: RecordIndex) -> [Person] {
        var result: [Person] = []
        var seenKeys: Set<String> = []

        for famc in kids(withTag: "FAMC") {
            guard let famKey = famc.val,
                  let family = index.family(for: famKey) else { continue }
            for wife in family.kids(withTag: "WIFE") {
                guard let wifeKey = wife.val, !seenKeys.contains(wifeKey),
                      let mother = index.person(for: wifeKey) else { continue }
                result.append(mother)
                seenKeys.insert(wifeKey)
            }
        }
        return result
    }
}

/// Extension for Spouses, Husbands, and Wives
public extension Person {

    /// Returns the first spouse by role (["HUSB"], ["WIFE"], or ["HUSB","WIFE"]).
    func spouse(in index: RecordIndex, roles: [String]) -> Person? {
        let selfKey = self.key
        for famsKey in kidVals(forTag: "FAMS") {
            guard let family = index.family(for: famsKey) else { continue }
            for role in roles {
                for key in family.kidVals(forTag: role) where key != selfKey {
                    if let spouse = index.person(for: key) { return spouse }
                }
            }
        }
        return nil
    }

    /// Convenience: first husband / first wife.
    func husband(in index: RecordIndex) -> Person? { spouse(in: index, roles: ["HUSB"]) }
    func wife(in index: RecordIndex)    -> Person? { spouse(in: index, roles: ["WIFE"]) }

    /// Returns all spouses across all FAMS, filtered by roles, deduped in encounter order.
    func spouses(in index: RecordIndex, roles: [String] = ["HUSB","WIFE"]) -> [Person] {
        let selfKey = self.key
        var seen = Set<String>()
        var spouses: [Person] = []
        for famKey in kidVals(forTag: "FAMS") {
            guard let family = index.family(for: famKey) else { continue }
            for role in roles {
                for key in family.kidVals(forTag: role) where key != selfKey && seen.insert(key).inserted {
                    if let spouse = index.person(for: key) { spouses.append(spouse) }
                }
            }
        }
        return spouses
    }

    func husbands(in index: RecordIndex) -> [Person] { spouses(in: index, roles: ["HUSB"]) }
    func wives(in index: RecordIndex)    -> [Person] { spouses(in: index, roles: ["WIFE"]) }

}

extension Person {

    // previousSibling returns the previous sibling of a person.
    func previousSibling(index: RecordIndex) -> Person? {
        // Get the family the person is a child in.
        guard let famKey = self.kidVal(forTag: "FAMC"), let family = index.family(for: famKey) else {
            return nil
        }
        // Get the children of the family.
        let children = family.children(in: index)
        // Get the previous sibling unless self is the first.
        guard let indexOfSelf = children.firstIndex(of: self), indexOfSelf > 0 else {
            return nil
        }
        return children[indexOfSelf - 1]
    }

    // nextSibling returns the next sibling of person 'self'.
    func nextSibling(index: RecordIndex) -> Person? {
        // Get the family the person is a child in.
        guard let famKey = self.kidVal(forTag: "FAMC"), let family = index.family(for: famKey) else {
            return nil
        }
        // Get the children of the family.
        let children = family.children(in: index)
        // Get the next sibling unless self is the last.
        guard let indexOfSelf = children.firstIndex(of: self), indexOfSelf < children.count - 1 else {
            return nil
        }
        return children[indexOfSelf + 1]
    }
}

public extension Person {

/// Returns all children of a Person by following the FAMS to CHIL pointers.
/// Order follows the Gedcom order; duplicate children are removed.
    func children(index: RecordIndex) -> [Person] {
        // Get the Families this Person is a spouse in.
        let families: [Family] = kids(withTag: "FAMS")
            .compactMap { $0.val }.compactMap { index.family(for: $0) }
        // Get the children from those families.
        let children: [Person] = families.flatMap { $0.kids(withTag: "CHIL") }
            .compactMap { $0.val }.compactMap { index.person(for: $0) }
        // Remove duplicate children.
        var seen = Set<String>()
        var result: [Person] = []
        for child in children {
            if seen.insert(child.key).inserted { result.append(child) }
        }
        return result
    }
}

extension GedcomNode {

    /// Returns the siblings of this person across every FAMC, in Gedcom file order.
    /// Duplicates (same person via multiple families) are removed by key.
    func siblings(index: RecordIndex) -> [GedcomNode] {
        // All families where this person is a child
        let families = self.kids(withTag: "FAMC")
            .compactMap { $0.val }
            .compactMap { index[$0] }  // FAM nodes

        // Flatten all CHIL pointers from those families, in order
        let rawKids = families
            .flatMap { $0.kids(withTag: "CHIL") }
            .compactMap { $0.val }
            .compactMap { index[$0] }  // INDI nodes

        // Exclude self, de-dupe by key, preserve first occurrence order
        let myKey = self.key
        var seen = Set<String>()
        var result: [GedcomNode] = []
        for kid in rawKids {
            guard kid.key != myKey else { continue }
            if let k = kid.key, seen.insert(k).inserted {
                result.append(kid)
            }
        }
        return result
    }

    /// Convenience overload when you have a Database handy.
    func siblings(database: Database?) -> [GedcomNode] {
        guard let index = database?.recordIndex else { return [] }
        return siblings(index: index)
    }
}
