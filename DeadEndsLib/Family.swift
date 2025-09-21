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
