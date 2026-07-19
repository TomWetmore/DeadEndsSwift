//
//  RunProgram.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 12 April 2026.
//  Last changed on 24 May 2026.
//
/// runProgram runs a DeadEnds program and sends its output to standard
/// output. The program is passed in as a string. The function lexes and
/// parses the program, building the program's internal parsed program
/// abstract syntax tree. If there are no compile errors it then creates
/// a runtime program from the parsed program and attempts to run it.
/// Runtime time errors are thrown.
///
/// In current DeadEnds software programs are run in two ways. First using
/// the run program function defined here. Second, programs are run from
/// the program page of the SwiftUI app.
///
/// The version defined here is intended for use in command line programs
/// and for debugging.
///

import Foundation
import Parsing

public enum FrontEndError: Error, CustomStringConvertible {
    case parseDidNotConsumeAllInput([Token])
    case missingEOF

    public var description: String {
        switch self {
        case .parseDidNotConsumeAllInput(let tokens):
            return "Parser did not consume all input. Remaining tokens: \(tokens)"
        case .missingEOF:
            return "Token stream did not end with EOF"
        }
    }
}

/// Run a program encoded in a string.
@MainActor
public func runProgram(source: String, database: Database,
                       output: ProgramOutput) async throws -> InterpResult {

    let source = normalizedSource(source)
    var lexer = Lexer(source: source)  // Create lexer and get the tokens.
    let tokens = lexer.tokenize()
    guard tokens.last?.kind == .eof else {
        throw FrontEndError.missingEOF
    }

    var input = tokens[...]  // Parse the tokens into a parsed program syntax tree.
    let parsedProgram = try ProgramParser().parse(&input)
    if let first = input.first, first.kind == .eof {
        input.removeFirst()
    }
    if !input.isEmpty {
        throw FrontEndError.parseDidNotConsumeAllInput(Array(input))
    }

    let program = Program(parsedProgram: parsedProgram, database: database,
                          output: output, userInterface: Patch())
    return try await program.interpretProgram()
}

public struct Patch: UserInterface {

    public func getPerson(prompt: String?) async -> Person? { return nil }

    public func getInteger(prompt: String?) async -> Int? { return nil }

    public func getString(prompt: String?) async -> String? { return nil }

    public func choosePerson(from set: PersonSet<ProgramValue>) async -> Person? { return nil }

    public func menuChoose(from list: List, prompt: String?) async -> Int? { return nil }

}
