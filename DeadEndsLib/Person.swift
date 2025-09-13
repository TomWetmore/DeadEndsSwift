//
//  Person.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 13 April 2025.
//  Last changed on 26 August 2025.
//

import Foundation


/// Enumerated type for sex values.
public enum SexType {
    case male
    case female
    case unknown
}

// GedcomNode extension where the GedcomNode is the root of a Person record.
extension GedcomNode {

    /// Return the SexType of a Person.
    public func sexOf() -> SexType? {
        guard let value = child(withTag: "SEX")?.value?.uppercased() else { return nil }
        switch value {
        case "M": return .male
        case "F": return .female
        case "U", "X": return .unknown
        default: return nil
        }
    }

    public var sexSymbol: String {
        switch (sexOf() ?? .unknown) {
        case .male: return "♂️"
        case .female: return "♀️"
        default: return "?"
        }
    }

    public var gedcomName: GedcomName? { GedcomName(from: self) }

    /// Returns true if a Person is female.
    func isFemale() -> Bool {
        return sexOf() == .female
    }

    // Returns true if a Person is male.
    func isMale() -> Bool {
        return sexOf() == .male
    }

    // father returns the first father (first HUSB in first FAMC) of this person.
    func fatherSimple(index: RecordIndex) -> GedcomNode? {
        guard let famKey = self.value(forTag: "FAMC"),
              let fam = index[famKey],
              let fatherKey = fam.value(forTag: "HUSB") else {
            return nil
        }
        return index[fatherKey]
    }

    // father returns the father a person. This version will scan multiple FAMC nodes, if there,
    // and return the first father found.
    public func father(index: RecordIndex) -> GedcomNode? {
        for famcKey in self.values(forTag: "FAMC") {
            guard let fam = index[famcKey],
                  let husbKey = fam.value(forTag: "HUSB"),
                  let father = index[husbKey] else {
                continue
            }
            return father
        }
        return nil
    }

    public func fathers(in index: RecordIndex) -> [GedcomNode] {
        var result: [GedcomNode] = []
        var seenKeys: Set<String> = []

        for famc in children(withTag: "FAMC") {
            guard let famKey = famc.value,
                  let family = index[famKey] else { continue }

            for husb in family.children(withTag: "HUSB") {
                guard let husbKey = husb.value,
                      !seenKeys.contains(husbKey),
                      let father = index[husbKey] else { continue }

                result.append(father)
                seenKeys.insert(husbKey)
            }
        }

        return result
    }

    // mother returns the first mother (first WIFE in first FAMC of this person.
    public func mother(index: RecordIndex) -> GedcomNode? {
        guard let famKey = self.value(forTag: "FAMC"),
              let fam = index[famKey],
              let motherKey = fam.value(forTag: "WIFE") else { return nil
        }
        return index[motherKey]
    }
}

extension GedcomNode {

    // previousSibling returns the previous sibling of a person.
    func previousSibling(index: RecordIndex) -> GedcomNode? {
        // Get the family the person is a child in.
        guard let famKey = self.value(forTag: "FAMC"), let family = index[famKey] else {
            return nil
        }
        // Get the children of the family.
        let children = childrenOf(family: family, index: index)
        // Get the previous sibling unless self is the first.
        guard let indexOfSelf = children.firstIndex(of: self), indexOfSelf > 0 else {
            return nil
        }
        return children[indexOfSelf - 1]
    }

    // nextSibling returns the next sibling of person 'self'.
    func nextSibling(index: RecordIndex) -> GedcomNode? {
        // Get the family the person is a child in.
        guard let famKey = self.value(forTag: "FAMC"), let family = index[famKey] else {
            return nil
        }
        // Get the children of the family.
        let children = childrenOf(family: family, index: index)
        // Get the next sibling unless self is the last.
        guard let indexOfSelf = children.firstIndex(of: self), indexOfSelf < children.count - 1 else {
            return nil
        }
        return children[indexOfSelf + 1]
    }
}

/// Returns all child persons of `person` by walking FAMS → CHIL pointers.
/// Order follows the GEDCOM order; duplicates (across multiple families) are removed.

    func childrenOf(person: GedcomNode, index: RecordIndex) -> [GedcomNode] {
        // Get families this person is a spouse in.
        let families: [GedcomNode] = person.children(withTag: "FAMS")
            .compactMap { $0.value }.compactMap { index[$0] }

        // Get the children from those families, keeping order.
        let rawChildren: [GedcomNode] = families.flatMap { $0.children(withTag: "CHIL") }
            .compactMap { $0.value }.compactMap { index[$0] }

        // De-dupe by key while preserving order
        var seen = Set<String>()
        var result: [GedcomNode] = []
        for child in rawChildren {
            if let key = child.key, seen.insert(key).inserted {
                result.append(child)
            }
        }
        return result
    }


extension GedcomNode {
    /// Returns the siblings of this person across every FAMC, in Gedcom file order.
    /// Duplicates (same person via multiple families) are removed by key.
    func siblings(index: RecordIndex) -> [GedcomNode] {
        // All families where this person is a child
        let families = self.children(withTag: "FAMC")
            .compactMap { $0.value }
            .compactMap { index[$0] }  // FAM nodes

        // Flatten all CHIL pointers from those families, in order
        let rawKids = families
            .flatMap { $0.children(withTag: "CHIL") }
            .compactMap { $0.value }
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
