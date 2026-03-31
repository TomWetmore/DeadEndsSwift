//
//  testOne.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 30 March 2026.
//  Last changed on 30 March 2026.
//

import Foundation
import DeadEndsLib

/// What this test does:
/// 1. Read the test (modified.ged) database.
/// 2. Create the partitions. Sort them by size.
/// 3. Show ancestors and descendants (I think this is redundant with other tests).
/// 4. Show connect data on the largest partition.
/// 5. Test deepcopying and rekeying.

func testOne() throws {
    print("Running test one")
    let database = loadDatabase()
    print("Make partitions")
    let partitions = database.partitions(includeFamilies: false)
    let sortedPartitions = partitions.sorted { $0.count > $1.count }
    print("There are \(partitions.count) partitions.\n")
    var sum = 0
    for partition in sortedPartitions {
        print("\(partition.count) records")
        sum += partition.count
    }
    print("There are a total of \(sum) records.")
    let mememe = database.recordIndex.person(for: "@I1@")
    if let mememe = mememe {
        print(mememe)
        let ancestors = database.recordIndex.ancestors(of: mememe)
        print("There are \(ancestors.count) ancestors")
        print("List found using the ancestors method")
        for ancestor in ancestors {
            print(ancestor.displayName())
        }
        print("numAncestors: \(database.recordIndex.numAncestors(of: mememe))")
        let descendants = database.recordIndex.descendants(of: mememe)
        print("There are \(descendants.count) descendants")
        for descendant in descendants {
            print(descendant.displayName())
        }
        print("numDescendants: \(database.recordIndex.numDescendants(of: mememe))")
    }
    // Show the connect data for the first (large) partition.
    let partition = sortedPartitions.first!
    let connectData = database.recordIndex.connections(partition: partition)
    print("There are \(connectData.count) connections.")
    for (key, data) in connectData {
        print("\(key): \(data)")
    }

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
