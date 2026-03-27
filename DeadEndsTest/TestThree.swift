//
//  File.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 3/26/26.
//  Last changed on 26 March 2026.
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
    let me = index.person(for: "@I41@")!
    let ancRoots = index.ancestors(of: me.root)
    let personSet = PersonSet(roots: ancRoots)
    print(personSet)

    let decRoots = index.descendants(of: me.root)
    let decPersonSet = PersonSet(roots: decRoots)
    print(decPersonSet)
}
