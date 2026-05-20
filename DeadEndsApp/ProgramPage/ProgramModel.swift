//
//  ProgramModel.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 April 2026.
//  Last changed on 20 May 2026.
//

import Foundation
import Observation
import DeadEndsLib
import Parsing
import AppKit

/// Program output object that buffers the full output of a Deadends program
/// into a string buffer while it is running. Output does no go to the output
/// text view until the program finishes running.
final class BufferedProgramOutput: ProgramOutput {

    private(set) var text: String = ""

    func write(_ s: String) {
        text += s
    }

    func flush() async {}  // Nothing to do.

    func clear() {
        text = ""
    }
}

@Observable
@MainActor
final class UIProgramOutput {
    var text: String = ""

    func clear() {
        text = ""
    }
}

/// Program page model.
@MainActor
@Observable
final class ProgramModel: UserInterface {



    var programName: String
    var source: String = ""  // Program source.
    var output = UIProgramOutput()

    var diagnostics: [Diagnostic] = []
    var parsedProgram: ParsedProgram? = nil

    var fileURL: URL? = nil
    var isDirty: Bool = false

    /// Create a program model with an unnamed empty source text.
    init(programName: String = "Untitled", source: String = "") {
        self.source = source
        self.programName = programName
    }

    /// Handle the compile button. This is the model operation that compiles
    /// a DeadEnds program. It wil either succeed or display diagnostics.
    func handleCompileButton() {

        diagnostics = []
        parsedProgram = nil
        output.clear()

        guard !source.isEmpty else { return }
        do {
            let normalized = normalizedSource(source)  // Smart quote hack.
            var lexer = Lexer(source: normalized)
            let tokens = lexer.tokenize()
            guard tokens.last?.kind == .eof else {
                throw FrontEndError.missingEOF
            }
            var input = tokens[...]  // Parse the tokens into a parsed program syntax tree.
            parsedProgram = try ProgramParser().parse(&input)
            if let first = input.first, first.kind == .eof {
                input.removeFirst()
            }
            if !input.isEmpty {
                throw FrontEndError.parseDidNotConsumeAllInput(Array(input))
            }
        } catch let error as FrontEndError {
            diagnostics = [convertFrontEndError(error)]
        } catch let error as ParseError {
                diagnostics = [Diagnostic(message: error.description, line: nil)]
        } catch {
            diagnostics = [Diagnostic(
                message: error.localizedDescription,
                line: nil
            )]
        }
    }

    /// Handles a run button press by interpreting the parsedProgram struct.
    /// Creates a Program object and runs it.
    func handleRunButton(database: Database) async {
        
        guard let parsedProgram else { return }  // Need a program to run.

        diagnostics = []
        output.clear()

        let buffer = BufferedProgramOutput()  // Output goes to string buffer.
        let program = Program(parsedProgram: parsedProgram, database: database,
                              output: buffer, userInterface: self)
        do {
            try await program.interpretProgram()  // Interpret the program.
            print("after interpret, output size =", buffer.text.count)  // DEBUG
            output.text = displayableOutput(buffer.text)  // Move buffered output to view.
        } catch let error as RuntimeError {
            output.text = displayableOutput(buffer.text)
            diagnostics = [Diagnostic(message: error.message,
                                      line: error.line > 0 ? error.line : nil)]
        } catch {
            output.text = displayableOutput(buffer.text)
            diagnostics = [Diagnostic(message: String(describing: error), line: 0)]
        }
    }

    @MainActor
    func openProgramFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            do {
                source = try String(contentsOf: url, encoding: .utf8)
                fileURL = url
                programName = url.lastPathComponent
                parsedProgram = nil
                diagnostics = []
                output.clear()
                isDirty = false
            } catch {
                diagnostics = [Diagnostic(message: "Could not open file: \(error.localizedDescription)", line: nil)]
            }
        }
    }

    @MainActor
    func saveProgramFile() {
        if let url = fileURL {
            saveProgramFile(to: url)
        } else {
            saveProgramFileAs()
        }
    }

    @MainActor
    func saveProgramFileAs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = programName == "Untitled" ? "Untitled.deadends" : programName

        if panel.runModal() == .OK, let url = panel.url {
            saveProgramFile(to: url)
        }
    }

    private func saveProgramFile(to url: URL) {
        do {
            try source.write(to: url, atomically: true, encoding: .utf8)
            fileURL = url
            programName = url.lastPathComponent
            isDirty = false
        } catch {
            diagnostics = [Diagnostic(message: "Could not save file: \(error.localizedDescription)", line: nil)]
        }
    }
}

extension ProgramModel {

    func getPerson(prompt: String?) async -> Person? { return nil }

    func choosePerson(from set: DeadEndsLib.PersonSet<DeadEndsLib.ProgramValue>) async -> DeadEndsLib.Person? {
        return nil
    }

    func menuChoose(from list: DeadEndsLib.List, prompt: String?) async -> Int? {
        return nil
    }
}

/// Mechanism to limit the size of the output view.
private let maxOutputChars = 100_000

private func displayableOutput(_ text: String) -> String {

    if text.count <= maxOutputChars {
        return text
    }
    return String(text.prefix(maxOutputChars))
        + "\n\n[output truncated: \(text.count) characters total]"
}

/// Simple diagnostic to start with.
struct Diagnostic: Identifiable {

    let id = UUID()
    let message: String
    public let line: Int?
}

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

/// Required because TextEditor uses smart quotes that are hard to turn off.
func normalizedSource(_ text: String) -> String {
    text
        .replacingOccurrences(of: "“", with: "\"")
        .replacingOccurrences(of: "”", with: "\"")
        .replacingOccurrences(of: "‘", with: "'")
        .replacingOccurrences(of: "’", with: "'")
}
