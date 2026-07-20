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

    /// Show the usage string for the deadends program.
    static func usage() {
        print("Usage: deadends database.ged program.dend")
    }

    /// The main function of the deadends program.
    static func main() async {

        // Get the command line arguments.
        let args = CommandLine.arguments
        guard args.count == 3 else {
            usage()
            return
        }

        let gedcomFile = args[1]
        let programFile = args[2]
        print("gedcom file is \(gedcomFile)\nprogram file is \(programFile)") // DEBUG

        // Load the database from the Gedcom file.
        var errLog = ErrorLog()
        guard let database = loadDatabase(from: gedcomFile, errlog: &errLog) else {
            print("\(errLog)\n")
            return
        }
        print("\(database)\n") // DEBUG -- show standard contents of the database.

        // Parse program.
        let programURL = URL(fileURLWithPath: programFile)
        let source: String
        do {
            source = try String(contentsOf: programURL, encoding: .utf8)
        } catch {
            print("Could not read program file \(programFile):")
            print(error)
            return
        }
        // Parse and run program.
        do {
            let result = try await runProgram(source: source,database: database,
                                              output: ConsoleOutput(),
                                              interface: TerminalInterface())
            print("\nProgram returned \(result)") // Temporary, depending on what InterpResult represents.
        } catch {
            print("Program failed:")
            print(error)
        }
    }
}
