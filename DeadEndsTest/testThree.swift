//
//  testThree.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 3/26/26.
//  Last changed on 28 March 2026.
//

import Foundation
import DeadEndsLib

func testThree() throws {
    print("Running test three")
    print("Reading Gedcom File into database")
    var errLog = ErrorLog()
    let database = loadDatabase(from: "/Users/ttw4/Desktop/DeadEndsVScode/Gedfiles/modified.ged", errlog: &errLog)
    guard let database = database else {
        throw RuntimeError.missingDatabase("Could not load Gedcom file into database.")
    }
    print("Database loaded successfully\n\(database)")
    let index = database.recordIndex
    let dvcw = index.person(for: "@I41@")!  // Daniel Van Cott Wetmore
    let ancRoots = index.ancestors(of: dvcw.root)
    let personSet = PersonSet(roots: ancRoots)
    print(personSet)

    let decRoots = index.descendants(of: dvcw.root)
    let decPersonSet = PersonSet(roots: decRoots)
    print(decPersonSet)

    // Create a PersonSet with just dvcw in it.
    let dvcwSet = PersonSet(root: dvcw.root)
    // Create and show the children set dvcw.
    let dvcwChildrenSet = dvcwSet.childrenSet(in: index)
    print("dvcw's children set")
    print("\(dvcwChildrenSet)")
    // Create and show dvcw's grandchildren.
    let grandchildren = dvcwChildrenSet.childrenSet(in: index)
    print("dvcw's grandchildren set")
    print("\(grandchildren)")
}
