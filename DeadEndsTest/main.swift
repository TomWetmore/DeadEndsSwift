//
//  main.swift
//  DeadEndsTest
//
//  Created by Thomas Wetmore on 4 September 2025.
//  Last changed on 30 March 2026.
//

import Foundation
import DeadEndsLib

runTest()

func runTest() {
    do {
        //try testThree()
        //try testTwo()
        try testPerson()
    } catch {
        print("Top level catch")
        exit(1)
    }
}

/// Read a database for the tests to use.
func loadDatabase() -> Database {
    print("Reading Gedcom File in database")
    var errLog = ErrorLog()
    let database = loadDatabase(from: "/Users/ttw4/Desktop/DeadEndsVScode/Gedfiles/modified.ged", errlog: &errLog)
    guard let database = database else { fatalError("Could not load database") }
    print("Database loaded successfully\n\(database)")
    return database
}



/// Return deep copies of all values in a record index.
func deepCopies(index: RecordIndex) -> RootList {
    index.values.map { $0.deepTreeCopy() }
}

// TODO: MOVE SOMEWHERE APPROPRIATE.
func checkDads(_ node: GedcomNode?) {
    guard let node else { return }

    var child = node.kid
    while let c = child {
        assert(c.dad === node)
        checkDads(c)
        child = c.sib
    }
}






