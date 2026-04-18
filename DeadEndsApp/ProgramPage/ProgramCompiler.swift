//
//  ProgramCompiler.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 April 2026.
//  Last changed on 15 April 2026.
//

import Foundation

/// Replace CompiledProgram with your actual AST/program type later.
typealias CompiledProgram = String

/// Represent the result of compiling a program.
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
protocol ProgramCompiler {
    
    func compile(source: String) -> CompileResult
}

struct DeadEndsProgramCompiler: ProgramCompiler {

    func compile(source: String) -> CompileResult {
        // call lexer/parser/semantic checker
        // convert parser errors into [Diagnostic]
        // return AST/program on success
        return .empty
    }
}
