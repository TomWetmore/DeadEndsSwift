//
//  testTwo.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 30 March 2026.
//  Last changed on 30 March 2026.
//


import Foundation
import DeadEndsLib

/// What this test does:
/// 1. Loads the modified.ged test database.
/// 2. Creates me and meRoot as the Person (me) and my root node.
/// 3. Use the descendants(of:) method to get my descendants.

func testTwo() throws {
    print("Running test two")
    print("Reading Gedcom File in database")
    var errLog = ErrorLog()
    let database = loadDatabase(from: "/Users/ttw4/Desktop/DeadEndsVScode/Gedfiles/modified.ged", errlog: &errLog)
    guard let database = database else {
        throw RuntimeError.missingDatabase("Could not load Gedcom file into database.")
    }
    print("Database loaded successfully\n\(database)")
    let index = database.recordIndex
    let me = index.person(for: "@I1@")!
    let meRoot = me.root
    let meDesc = index.descendants(of: me)
    let meRootDesc = index.descendants(of: meRoot)
    for d in meDesc {
        print("descendant of me: \(d.name)")
    }
    for d in meRootDesc {
        print("descendant of meRoot: \(d)")
    }
    print("number of descendants of me is \(index.numDescendants(of: me))")
    print("number of descendants of meRoot is \(index.numDescendants(of: meRoot))")

    let meAnc = index.ancestors(of: me)
    let meRootAnc = index.ancestors(of: meRoot)
    for a in meAnc {
        print("ancestor of me: \(a.name)")
    }
    for a in meRootAnc {
        print("ancestor of meRoot: \(a)")
    }
    print("number of ancestors of me is \(index.numAncestors(of: me))")
    print("number of ancestors of meRoot is \(index.numAncestors(of: meRoot))")
}
