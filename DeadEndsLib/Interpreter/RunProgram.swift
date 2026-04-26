//
//  RunProgram.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 12 April 2026.
//  Last changed on 25 April 2026.
//
/// runProgram runs a DeadEnds program and sends the output to a
/// ProgramOutput object. The program is passed in as a string.
/// The function compiles the program (lexes and parses) the string,
/// and then runs the resulting parsed program. If there are issues
/// the function throws an error of various types.
///
/// This function is designed more for command line use than
/// application use. There is another version of the programming code
/// found in the programming page model.
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
public func runProgram(source: String, database: Database,
                       output: ProgramOutput) throws -> InterpResult {

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
                          output: ConsoleOutput())  // Build runtime program object.
    return try program.interpretProgram()  // Interpret the program.
}
