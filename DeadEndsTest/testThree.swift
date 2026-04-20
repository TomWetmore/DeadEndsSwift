//
//  testThree.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 26 March 2026.
//  Last changed on 30 March 2026.
//

import Foundation
import DeadEndsLib

/// What does this test? First tests for the Person Set.
/// 1. Get the ancestor roots of dvcw using ancestors(of root:)
/// 2. Get the corresponding person set of those ancestors.
/// 3. Show that person set.
/// 4. Ditto descendants.
/// 5. Create a person set with just dvcw.
/// 6. Create the children set from it.
/// 7. Create the grandchildren set from the children set.

func testThree() throws {
    print("Running test three")
    let database = loadDatabase()
    let index = database.recordIndex
    let dvcw = index.person(for: "@I41@")!  // Daniel Van Cott Wetmore
    let ancRoots = index.ancestors(of: dvcw.root)
    let personSet = PlainPersonSet(roots: ancRoots)
    print(personSet)

    let decRoots = index.descendants(of: dvcw.root)
    let decPersonSet = PlainPersonSet(roots: decRoots)
    print(decPersonSet)

    // Create a PersonSet with just dvcw in it.
    let dvcwSet = PlainPersonSet(root: dvcw.root)
    // Create and show the children set dvcw.
    let dvcwChildrenSet = dvcwSet.childrenSet(in: index)
    print("dvcw's children set has \(dvcwChildrenSet.count) members")
    print("\(dvcwChildrenSet)")
    // Create and show dvcw's grandchildren.
    let grandchildren = dvcwChildrenSet.childrenSet(in: index)
    print("dvcw's grandchildren set")
    print("\(grandchildren)")
}
