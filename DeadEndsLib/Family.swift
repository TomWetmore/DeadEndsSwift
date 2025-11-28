//
//  Family.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 13 April 2025.
//  Last changed on 20 September 2025.
//

import Foundation

public struct Family: Record {
    public let root: GedcomNode
    public init?(_ root: GedcomNode) { guard root.tag == "FAM", root.key != nil  else { return nil }
        self.root = root
    }
}

extension Family {

    /// Returns the first husband in a Family.
    public func husband(in index: RecordIndex) -> Person? {
        guard let husbKey = kidVal(forTag: "HUSB"), let husband = index.person(for: husbKey)
        else { return nil }
        return husband
    }

    /// Returns the first wife in a Family.
    public func wife(in index: RecordIndex) -> Person? {
        guard let wifeKey = kidVal(forTag: "WIFE"), let wife = index.person(for: wifeKey)
        else { return nil }
        return wife
    }

    /// Returns the children in a Family.
    public func children(in index: RecordIndex) -> [Person] {
        return kids(withTag: "CHIL").compactMap { node in
            node.val.flatMap { index.person(for: $0) }
        }
    }

    // Returns the husbands in a Family. (For unconventional families.)
    public func husbands(in index: RecordIndex) -> [Person] {
        return kids(withTag: "HUSB").compactMap { node in
            node.val.flatMap { index.person(for: $0)}
        }
    }

    // Returns the wives in a Family. (For unconventional families.)
    public func wives(in index: RecordIndex) -> [Person] {
        return kids(withTag: "WIFE").compactMap { node in
            node.val.flatMap { index.person(for: $0)}
        }
    }
}

public extension Family {

    /// Returns the first spouse (husband or wife) who is **not** the given person.
    /// Returns `nil` if the given person is not part of this family, or if no other spouse exists.
    func spouse(of person: Person, in index: RecordIndex) -> Person? {
        // Sanity check: ensure `person` is a spouse in this family
        let husband = husband(in: index)
        let wife = wife(in: index)

        guard person.root.key == husband?.root.key || person.root.key == wife?.root.key else {
            // The person isn’t a spouse in this family
            return nil
        }

        // Return the opposite spouse, if any
        if person.root.key == husband?.root.key {
            return wife
        } else if person.root.key == wife?.root.key {
            return husband
        } else {
            return nil
        }
    }

    /// Returns all spouses (husband and wife) who are **not** the given person.
    /// If the given person isn’t part of the family, returns an empty array.
    func oldspouses(of person: Person, in index: RecordIndex) -> [Person] {
        let husband = husband(in: index)
        let wife = wife(in: index)

        // Sanity check
        guard person.root.key == husband?.root.key || person.root.key == wife?.root.key else {
            return []
        }

        // Collect all nonmatching spouses
        var result: [Person] = []
        if let h = husband, h.root.key != person.root.key {
            result.append(h)
        }
        if let w = wife, w.root.key != person.root.key {
            result.append(w)
        }
        return result
    }

    // TODO: After change below this method has not been tested.
    func spouses(of person: GedcomNode, in index: RecordIndex) -> [Person] {
        //var foundSelf = false
        var results: [Person] = []

        let spouseKeys = self.kidVals(forTags: ["HUSB", "WIFE"])
        for key in spouseKeys {
            if key != person.key, let root = index[key], let spouse = Person(root) {
                results.append(spouse)
            }
//            if key == person.key {
//                foundSelf = true
//            } else if let root = index[key], let spouse = Person(root) {
//                results.append(spouse)
//            }
        }
        return results
    }
}

extension Family: Equatable, Hashable {
    public static func == (lhs: Family, rhs: Family) -> Bool {
        lhs.root.key == rhs.root.key
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(root.key)
    }
}

extension Family: Identifiable {
    public var id: String { key }
}
