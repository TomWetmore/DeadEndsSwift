//
//  ProgramModel.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 April 2026.
//  Last changed on 15 April 2026.
//

import Foundation
import Observation
import DeadEndsLib

// MARK: - Source Location

@MainActor
@Observable
final class ProgramModel {
    var programName: String
    var sourceText: String

    var compileDiagnostics: [Diagnostic] = []
    var compiledProgram: CompiledProgram? = nil
    var lastCompileSucceeded: Bool = false

    // Future execution support
    var outputText: String = ""
    var runtimeDiagnostics: [Diagnostic] = []
    // var traceEvents: [TraceEvent] = []
    // var pendingInteraction: ProgramInteractionRequest? = nil

    init(programName: String = "Untitled", sourceText: String = "") {
        self.sourceText = sourceText
        self.programName = programName
    }

    func applyCompileResult(_ result: CompileResult) {
        compiledProgram = result.program
        compileDiagnostics = result.diagnostics
        lastCompileSucceeded = result.succeeded
    }

    func clearCompileResults() {
        compiledProgram = nil
        compileDiagnostics = []
        lastCompileSucceeded = false
    }
}

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
