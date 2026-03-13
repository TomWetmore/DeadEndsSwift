//
//  main.swift
//  DeadEndsTest
//
//  Created by Thomas Wetmore on 4 September 2025.
//  Last changed on 13 March 2026.
//

import Foundation
import DeadEndsLib

runTest()

func runTest() {
    do {
        try runTestOne()
    } catch {
        print("Top level catch")
        exit(1)
    }
}

// Load a database from a Gedcom file.
func runTestOne() throws {
    print("Reading Gedcom file into database")
    var errLog = ErrorLog()
    let database = loadDatabase(from: "/Users/ttw4/Desktop/DeadEndsVScode/Gedfiles/modified.ged", errlog: &errLog)
    guard let database = database else {
        throw RuntimeError.missingDatabase("Could not load Gedcom file into database.")
    }
    print("Database loaded successfully\n\(database)")

    // Test deep copying: get an array of deep copies of all the nodes.
    let copies: RootList = deepCopies(index: database.recordIndex)
    let countDeep = copies.reduce(0) { $0 + $1.count }
    print("After deep copy there are \(countDeep) nodes.")
    copies.forEach(checkDads)

    // Test rekeying a database.
    let rekeyedDatabase = database.rekeyDatabase()
    if let rekeyed = rekeyedDatabase {
        print("Rekeyed database created\n\(rekeyed)")
    } else {
        print("Rekeying failed.")
    }
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






