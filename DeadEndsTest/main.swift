//
//  main.swift
//  DeadEndsTest
//
//  Created by Thomas Wetmore on 4 September 2025.
//  Last changed on 12 March 2026.
//

import Foundation
import DeadEndsLib

runTest()

func runTest() {
    print("hello world")
    do {
        try runTestOne()
    } catch {
        print("Top level catch")
        exit(1)
    }
}

// Count the nodes in the database.
// Create a randomized recordinde.
// Count the nodes in the randomized record index.

// Load a database from a Gedcom file.
func runTestOne() throws {
    print("Reading Gedcom file into database")
    var errLog = ErrorLog()
    let database = loadDatabase(from: "/Users/ttw4/Desktop/DeadEndsVScode/Gedfiles/modified.ged", errlog: &errLog)
    guard let database = database else {
        throw RuntimeError.missingDatabase("Could not load Gedcom file into database.")
    }
    print("Database loaded successfully")
    let count = countNodes(index: database.recordIndex)
    print("There are \(count) nodes in the database")

    // Get an array of deep copies of all the nodes.
    let copies: RootList = deepCopies(index: database.recordIndex)
    let countDeep = copies.reduce(0) { $0 + $1.count }
    print("After deep copy: \(countDeep)")
    copies.forEach(checkDads)

    // Rekey the copied record index.
    let rekeyed = database.rekeyRecordIndex()
    // Show number of records in rekeyed index.
    print("rekeyed.count is \(rekeyed.count)")
    // Print how many nodes are in all the records.
    print("Number of nodes in rekeyed index is \(countNodes(index: rekeyed))")
    // Show keys in new record index.
    rekeyed.forEach { print($0) }
}

/// Count all nodes in a record index.
func countNodes(index: RecordIndex) -> Int {
    index.values.map { $0.count }.reduce(0, +)
}

func countDeep(index: RecordIndex) -> Int {
    deepCopies(index: index).reduce(0) { $0 + $1.count }
}

func deepCopies(index: RecordIndex) -> RootList {
    index.values.map { $0.deepTreeCopy() }
}

/// Return deep copy of a record index.
/// IS THERE A USE CASE FOR THIS?
//func deepCopy(index: RecordIndex) -> RecordIndex {
//}

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






