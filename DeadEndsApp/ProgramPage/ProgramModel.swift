//
//  ProgramModel.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 April 2026.
//  Last changed on 23 May 2026.
//

import Foundation
import DeadEndsLib
import AppKit
import UniformTypeIdentifiers

/// Conformance that buffers DeadEnds program output to a string while the
/// program is running. Output is periodically sent to the text view.
final class BufferedOutput: ProgramOutput {

    private(set) var text = ""
    let publish: @MainActor (String) -> Void

    init(publish: @escaping @MainActor (String) -> Void) {
        self.publish = publish
    }

    /// Append a string to the buffer.
    func write(_ s: String) {
        text += s
    }

    /// Flush the string.
    @MainActor func flush() async {
        let current = text
        await MainActor.run {
            publish(displayableOutput(current))
        }
    }

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

/// Current approach to user interface requests. This only handles the
/// getperson() request. A more general approach may be added later.
struct GetPersonRequest: Identifiable {
    let id = UUID()
    let prompt: String
}

/// Program page model.
@MainActor
@Observable
final class ProgramModel {

    var programName: String
    var source: String = ""  // Program source.
    var output = UIProgramOutput()

    var diagnostics: [Diagnostic] = []
    var parsedProgram: ParsedProgram? = nil

    var fileURL: URL? = nil
    var isDirty: Bool = false

    /// Get person interface.
    var personRequest: GetPersonRequest?
    var personContinuation: CheckedContinuation<Person?, Never>?

    /// Create a program model with unnamed, empty source text.
    init(programName: String = "Untitled", source: String = "") {
        self.source = source
        self.programName = programName
    }

    /// Handle the compile button; tries to compile a program.
    /// It will either succeed or display a diagnostic message.
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
            var input = tokens[...]  // Parse the tokens into a parsed program.
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

    /// Handle the run button; create a program and try to interpret it.
    func handleRunButton(database: Database) async {
        
        guard let parsedProgram else { return }
        diagnostics = []
        output.clear()

        let buffer = BufferedOutput { [weak self] text in self?.output.text = text }
        let program = Program(parsedProgram: parsedProgram, database: database,
                              output: buffer, userInterface: self)
        do {
            try await program.interpretProgram()
            //print("after interpret, output size =", buffer.text.count)  // DEBUG
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

    /// Handle the open button; read a DeadEnds program from the file system.
    @MainActor
    func openProgramFile() {
        
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            .plainText,
            UTType(filenameExtension: "ll")!,
            UTType(filenameExtension: "dend")!
        ]
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
                diagnostics = [
                    Diagnostic(
                        message: "Could not open file: \(error.localizedDescription)",
                        line: nil
                    )
                ]
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

/// Conformance of the user interface protocol for SwiftUI.
@MainActor
extension ProgramModel: UserInterface {

    /// Protocol method for the getperson() operation.
    func getPerson(prompt: String?) async -> Person? {
        personRequest = GetPersonRequest(prompt: prompt ?? "Enter a person")
        return await withCheckedContinuation { continuation in
            personContinuation = continuation
        }
    }

    /// Continuation for the get person method.
    func finishGetPerson(_ person: Person?) {
        personRequest = nil
        personContinuation?.resume(returning: person)
        personContinuation = nil
    }

}
