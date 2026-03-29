//
//  testPerson.swift
//  DeadEndsTest
//
//  Created by Thomas Wetmore on 28 March 2026.
//  Last changed on 28 March 2026.
//

import Foundation
import DeadEndsLib

func testPerson() {
    let database = loadDatabase()
    let index = database.recordIndex
    let me = requirePerson(with: "@I1@", in: index)
    let parents = me.parents(in: index)
    print("\(me)  \(parents)")
}

func testParents() {
    // Create me
    // Get my parents
    // Show all three.
}
