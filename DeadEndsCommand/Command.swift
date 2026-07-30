//
//  main.swift
//  DeadEndsCommand
//
//  Created by Thomas Wetmore on 17 July 2026.
//  Last changed on 30 July 2026.
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
        print("\(database)\n") // DEBUG -- show the database summary.

        do {
            let parsedProgram = try parseFullProgram(fileURL: URL(fileURLWithPath: programFile))
            let program = Program(parsedProgram: parsedProgram, database: database,
                output: ConsoleOutput(), userInterface: TerminalInterface())
            let result = try await program.interpretProgram()
            print("\nProgram returned \(result)") // DEBUG.
        }
        catch let error as ParseError {
            print(error)
        }
        catch let error as RuntimeError {
            print(error)
        }
        catch {
            print("Unexpected error:")
            print(error)
        }
    }
}

