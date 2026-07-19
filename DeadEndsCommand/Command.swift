//
//  main.swift
//  DeadEndsCommand
//
//  Created by Thomas Wetmore on 17 July 2026.
//  Last changed on 18 July 2026.
//

import Foundation
import DeadEndsLib

@main
struct DeadEndsCommand {

    static func usage() {
        print("Usage: deadends database.ged program.dend")
    }

    static func main() {

        let args = CommandLine.arguments

        guard args.count == 3 else {
            usage()
            return
        }

        let gedcomFile = args[1]
        let programFile = args[2]

        print("gedcom file is \(gedcomFile)\nprogram file is \(programFile)") // DEBUG

        // Load database
        var errLog = ErrorLog()
        guard let database = loadDatabase(from: gedcomFile, errlog: &errLog) else {
            print("\(errLog)\n")
            return
        }
        print("\(database)\n") // DEBUG

        // Parse program.

    }
}


// Parse program


// Run interpreter
