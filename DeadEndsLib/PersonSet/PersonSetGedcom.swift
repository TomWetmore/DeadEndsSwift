//
//  PersonSetGedcom.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 18 April 2026.
//  Last changed on 25 September 2026.
//

import Foundation

/// From a list of Persons return a RecordIndex that holds the records needed to generate
/// a Gedcom file for the Persons.

func personsToRecordIndex(_ persons: [Person], in index: RecordIndex) -> [RecordKey: Record] {

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

