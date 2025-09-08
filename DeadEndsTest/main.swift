//
//  main.swift
//  DeadEndsTest
//
//  Created by Thomas Wetmore on 4 September 2025.
//  Last changed on 4 September 2025.
//

import Foundation
import DeadEndsLib

// Example input
let raw = "Thomas Trask Van Cott /Wetmore/ IV Ph.D. Great Guy"

// Build a GedcomName from the string
guard var base = GedcomName(string: raw) else {
    fatalError("Could not parse GedcomName from: \(raw)")
}

// Settings for display
let surnameFirst = true
let uppercaseSurname = false

// Print from wide to narrow
for limit in stride(from: 60, through: 0, by: -1) {
    print("\(limit): " + base.displayName(limit: limit))
}

for limit in stride(from: 40, through: 0, by: -1) {
    print("\(limit): " + base.displayName(upSurname: true, limit: limit))
}

for limit in stride(from: 49, through: 0, by: -1) {
    print("\(limit): " + base.displayName(surnameFirst: true, limit: limit))
}

for limit in stride(from: 40, through: 0, by: -1) {
    print("\(limit): " + base.displayName(upSurname: true, surnameFirst: true, limit: limit))
}

for limit in stride(from: 40, through: 0, by: -1) {
    print(DeadEndsLib.displayName(name: raw, limit: limit))
}





