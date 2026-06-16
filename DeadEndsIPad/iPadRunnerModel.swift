//
//  iPadRunnerModel.swift
//  DeadEndsIPad
//
//  Created by Thomas Wetmore on 13 June 2026.
//  Last changed on 15 June 2026.
//

import SwiftUI
import DeadEndsLib
import UniformTypeIdentifiers



@MainActor
@Observable
final class IPadRunnerModel: UserInterface {

    var database: Database?
    var source: String = ""
    var programName: String?
    var output = UIProgramOutput()
    var isDirty = false
    var parsedProgram: ParsedProgram?
    var databaseState: StatusState = .initial
    var programLoadState: StatusState = .initial
    var compileState: StatusState = .initial
    var runState: StatusState = .initial

    var diagnostics: [Diagnostic] = []

    func loadProgram(from url: URL) {
        do {
            let ok = url.startAccessingSecurityScopedResource()
            defer {
                if ok { url.stopAccessingSecurityScopedResource() }
            }

            source = try String(contentsOf: url, encoding: .utf8)
            programName = url.lastPathComponent
            sourceWasEdited()
            programLoadState = .success
        } catch {
            diagnostics = [
                Diagnostic(message: "Could not open program: \(error.localizedDescription)", line: nil)
            ]
            programLoadState = .failure
        }
    }

    func loadDatabase(from url: URL) {
        databaseState = .working

        let ok = url.startAccessingSecurityScopedResource()
        defer {
            if ok { url.stopAccessingSecurityScopedResource() }
        }

        var log = ErrorLog()

        if let database = DeadEndsLib.loadDatabase(from: url.path, errlog: &log) {
            self.database = database
            databaseState = .success
        } else {
            databaseState = .failure
            print("Failed to load GEDCOM file:\n\(log)")
        }
    }

    /// Copied from ProgramModel.
    /// Handle the compile button; tries to compile a program.
    /// It will either succeed or display a diagnostic message.
    func handleCompileButton() {

        compileState = .working
        diagnostics = []
        parsedProgram = nil
        output.clear()

        guard !source.isEmpty else {
            compileState = .initial
            return
        }

        do {
            let normalized = normalizedSource(source)  // Quote hack.
            var lexer = Lexer(source: normalized)
            let tokens = lexer.tokenize()
            guard tokens.last?.kind == .eof else {
                throw FrontEndError.missingEOF
            }
            var input = tokens[...]
            parsedProgram = try ProgramParser().parse(&input)
            if let first = input.first, first.kind == .eof {
                input.removeFirst()
            }
            if !input.isEmpty {
                throw FrontEndError.parseDidNotConsumeAllInput(Array(input))
            }
            compileState = .success

        } catch let error as FrontEndError {
            diagnostics = [convertFrontEndError(error)]
            compileState = .failure
        } catch let error as ParseError {
            diagnostics = [Diagnostic(
                message: error.description,
                line: nil
            )]
            compileState = .failure
        } catch {
            diagnostics = [Diagnostic(
                message: error.localizedDescription,
                line: nil
            )]
            compileState = .failure
        }
    }

    /// Copied from ProgramModel.
    /// Handle the run button; create a program and try to interpret it.
    func handleRunButton(database: Database) async {

        runState = .working
        guard let parsedProgram else {
            runState = .initial
            return
        }
        diagnostics = []
        output.clear()

        let buffer = BufferedOutput { [weak self] text in self?.output.text = text }
        let program = Program(parsedProgram: parsedProgram, database: database,
                              output: buffer, userInterface: self)
        do {
            try await program.interpretProgram()
            //print("after interpret, output size =", buffer.text.count)  // DEBUG
            output.text = displayableOutput(buffer.text)  // Move buffered output to view.
            runState = .success
        } catch let error as RuntimeError {
            output.text = displayableOutput(buffer.text)
            diagnostics = [Diagnostic(message: error.message,
                                      line: error.line > 0 ? error.line : nil)]
            runState = .failure
        } catch {
            output.text = displayableOutput(buffer.text)
            diagnostics = [Diagnostic(message: String(describing: error), line: 0)]
            runState = .failure
        }
    }

    /// Copied from ProgramModel.
    /// Called when the user starts to edit the edit field.
    func sourceWasEdited() {
        isDirty = true
        parsedProgram = nil
        compileState = .initial
        runState = .initial
        diagnostics = []
    }

    func getPerson(prompt: String?) async -> Person? { return nil }
    func getInteger(prompt: String?) async -> Int? { return nil }
    func getString(prompt: String?) async -> String? { return nil }
}


/// Copied from ProgramModel:
/// Simple diagnostic to start with.
struct Diagnostic: Identifiable {

    let id = UUID()
    let message: String
    public let line: Int?
}

/// Copied from ProgramModel:
/// Required because TextEditor uses smart quotes that are hard to turn off.
func normalizedSource(_ text: String) -> String {
    text
        .replacingOccurrences(of: "“", with: "\"")
        .replacingOccurrences(of: "”", with: "\"")
        .replacingOccurrences(of: "‘", with: "'")
        .replacingOccurrences(of: "’", with: "'")
}

/// Copied from ProgramModel.
func convertFrontEndError(_ error: FrontEndError) -> Diagnostic {
    switch error {
        
    case .missingEOF:
        return Diagnostic(message: "Missing EOF", line: nil)
    case .parseDidNotConsumeAllInput(let tokens):
        return Diagnostic(
            message: "Unexpected input after end of program",
            line: tokens.first?.line
        )
    }
}
