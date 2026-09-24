//
//  PersonSetGedcom.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 18 April 2026.
//  Last changed on 23 September 2026.
//

import Foundation

/// From a list of Persons return a RecordIndex that holds the records needed to generate
/// a Gedcom file for the Persons.

func personsToRecordIndex(persons: [Person], in index: RecordIndex) -> [RecordKey: Record] {

    let personKeys = Set(persons.map(\.key))
    var newIndex = [RecordKey: Record]()

    // Make deep copies of the persons.
    for person in persons {
        let copy = person.deepCopy()
        newIndex[copy.key] = copy
    }

    // Make deep copies of the families referred to by the persons.
    var seenFamilyKeys = Set<RecordKey>()
    for person in persons {

        let familyNodes = person.kids(withTags: ["FAMC", "FAMS"])
        for familyNode in familyNodes {

            let familyRoot = index.requireRoot(from: familyNode, tag: "FAM")
            let familyKey = familyRoot.requireKey
            guard seenFamilyKeys.insert(familyKey).inserted else {
                continue
            }
            let copy = Family(familyRoot.deepCopy())

            // Remove HUSB, WIFE and CHIL links to Persons not in list.
            for node in copy.kids(withTags: ["HUSB", "WIFE", "CHIL"]) {
                if !personKeys.contains(node.requireLink) {
                    node.remove()
                }
            }
            newIndex[copy.key] = copy
        }
    }
    return newIndex
}

extension GedcomNode {

    /// Create and return a deep copy of a GedcomNode and the full tree below it.

    func deepCopy(dad: GedcomNode? = nil) -> GedcomNode {

        let node = GedcomNode(key: key, tag: tag, val: val)
        node.dad = dad

        if let kid {
            node.kid = kid.deepCopy(dad: node)
        }
        if let sib {
            node.sib = sib.deepCopy(dad: dad)
        }
        return node
    }

    /// Cleanly remove a GedcomNode (and those below it) from anywhere in a GedcomNode tree.

    func remove() {

        if let prev = prevSib {
            prev.sib = sib
        } else {
            dad?.kid = sib
        }
    }
}
