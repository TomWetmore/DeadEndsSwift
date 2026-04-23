//
//  ProgramModel.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 April 2026.
//  Last changed on 21 April 2026.
//

import Foundation
import Observation
import DeadEndsLib

/// Sink for report output.
@MainActor
final class UIProgramOutput: ProgramOutput, ObservableObject {

    @Published var text: String = ""

    func write(_ text: String) {
        self.text += text
    }
}

/// Program page model.
@MainActor
@Observable
final class ProgramModel {

    var programName: String
    var source: String = ""  // Program source.
    var output: String = ""  // Program output.

    var diagnostics: [Diagnostic] = []
    var compiledProgram: ParsedProgram? = nil
    var lastCompileSucceeded: Bool = false


    init(programName: String = "Untitled", source: String = "") {
        self.source = source
        self.programName = programName
    }

    func applyCompileResult(_ result: CompileResult) {
        compiledProgram = result.program
        diagnostics = result.diagnostics
        lastCompileSucceeded = result.succeeded
    }

    func clearCompileResults() {
        compiledProgram = nil
        diagnostics = []
        lastCompileSucceeded = false
    }

    /// Model operation to compile a program and set model properties.
    func compile() {

        diagnostics = []  // Error (later errors) found in last compile try.
        compiledProgram = nil  // Parsed program object upon success.

        let compileResult = ProgramCompiler.compile(source: source)
        compiledProgram = compileResult.program
        diagnostics = compileResult.diagnostics
    }}

/// Identify a location in source code.
struct SourceLocation: Hashable, Codable {

    var line: Int
    var column: Int? = nil

    var displayString: String {
        if let column {
            return "Line \(line), Col \(column)"
        } else {
            return "Line \(line)"
        }
    }
}

// MARK: - Diagnostics

enum DiagnosticKind: String, Codable, Hashable {

    case lexical
    case syntax
    case semantic
    case runtime
}

enum DiagnosticSeverity: String, Codable, Hashable {

    case info
    case warning
    case error
}

struct Diagnostic: Identifiable, Hashable, Codable {

    let id: UUID
    var kind: DiagnosticKind
    var severity: DiagnosticSeverity
    var message: String
    var location: SourceLocation?

    init(
        id: UUID = UUID(),
        kind: DiagnosticKind,
        severity: DiagnosticSeverity = .error,
        message: String,
        location: SourceLocation? = nil
    ) {
        self.id = id
        self.kind = kind
        self.severity = severity
        self.message = message
        self.location = location
    }
}
