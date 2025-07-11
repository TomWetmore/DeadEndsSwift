//
//  Family.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 13 April 2025.
//  Last changed on 22 June 2025.
//

import Foundation

extension GedcomNode {

    // Returns the list of persons (root nodes) who are the children in a family.
    // The order of the children matches the order of CHIL nodes in the family.
    func children(index: RecordIndex) -> [GedcomNode] {
        return self.values(forTag: "CHIL").compactMap { index[$0] }
    }
}


