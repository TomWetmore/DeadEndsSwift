//
//  Family.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 13 April 2025.
//  Last changed on 22 June 2025.
//

import Foundation

/// Returns the list of children (root nodes) in a family. Order is maintained.
func childrenOf(family: GedcomNode, index: RecordIndex) -> [GedcomNode] {
    return family.values(forTag: "CHIL").compactMap { index[$0] }
}



