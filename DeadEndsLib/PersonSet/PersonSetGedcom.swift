//
//  PersonSetGedcom.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 18 April 2026.
//  Last changed on 22 September 2026.
//

import Foundation

/// From a list of Persons return an index holding the records needed to generate the Gedcom
/// file for the Persons.

func personsToRecordIndex(in index: RecordIndex, persons: [Person]) -> [RecordKey: Record] {

    let personKeys = Set(persons.map(\.key))
    var newIndex = [RecordKey: Record]()

    // Make deep copies of the persons.
    for person in persons {
        let copy = Person(person.root.deepCopy())
        newIndex[copy.key] = copy
    }

    // Make deep copies of the families referred to by the persons.
    var seenFamilies = Set<RecordKey>()
    for person in persons {

        let familyNodes = person.kids(withTags: ["FAMC", "FAMS"])
        for familyNode in familyNodes {

            let familyRoot = index.requireRoot(from: familyNode, tag: "FAM")
            let familyKey = familyRoot.requireKey
            guard seenFamilies.insert(familyKey).inserted else {
                continue
            }
            let copy = Family(familyRoot.deepCopy())

            for node in copy.kids(withTags: ["HUSB", "WIFE", "CHIL"]) {
                if !personKeys.contains(node.requireKey) {
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

    /// Cleanly remove a GedcomNode from anywhere in a GedcomNode tree.

    func remove() {

        if let prev = prevSib {
            prev.sib = sib
        } else {
            dad?.kid = sib
        }
    }
}
