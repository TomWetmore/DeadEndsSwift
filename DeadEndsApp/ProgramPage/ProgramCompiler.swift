//
//  ProgramCompiler.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 April 2026.
//  Last changed on 21 April 2026.
//

import Foundation
import DeadEndsLib

/// Replace CompiledProgram with your actual AST/program type later.
typealias CompiledProgram = ParsedProgram

/// Result of compiling a program.
struct CompileResult {

    var program: CompiledProgram?
    var diagnostics: [Diagnostic]

    /// Compile was successful if there is a program and no diagnostics with .error severity.
    var succeeded: Bool {
        program != nil && !diagnostics.contains(where: { $0.severity == .error })
    }

    /// Static property encoding an empty compile result.
    static let empty = CompileResult(program: nil, diagnostics: [])
}

/// Program compiler protocol.
//protocol ProgramCompiler {
//    
//    func compile(source: String) -> CompileResult
//}

struct ProgramCompiler {

    static func compile(source: String) -> CompileResult {
        // 1. Create a lexer and get the tokens.
        var lexer = Lexer(source: source)
        var tokens = lexer.tokenize()
        // 2. Compile the tokens into a ParsedProgram.

        // convert parser errors into [Diagnostic]
        // return AST/program on success
        return .empty
    }
}
