//
//  main.swift
//  DeadEndsTest
//
//  Created by Thomas Wetmore on 4 September 2025.
//  Last changed on 4 September 2025.
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
    let deepCopies: [Root] = deepCopies(index: database.recordIndex)
    let countDeep = deepCopies.reduce(0) { $0 + $1.count }
    print("After deep copy: \(countDeep)")
    deepCopies.forEach(checkDads)
}

typealias Root = GedcomNode

//func countNodes(index: RecordIndex) -> Int {
//    index.reduce(0) { total, pair in
//        let (_, root) = pair
//        return total + root.count()
//    }
//}

func countNodes(index: RecordIndex) -> Int {
    index.values
        .map { $0.count }
        .reduce(0, +)
}

func countDeep(index: RecordIndex) -> Int {
    deepCopies(index: index).reduce(0) { $0 + $1.count }
}

func deepCopies(index: RecordIndex) -> [Root] {
    index.values.map { $0.deepTreeCopy() }
}


func checkDads(_ node: GedcomNode?) {
    guard let node else { return }

    var child = node.kid
    while let c = child {
        assert(c.dad === node)
        checkDads(c)
        child = c.sib
    }
}






