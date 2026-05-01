//
//  ProgramModel.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 April 2026.
//  Last changed on 23 April 2026.
//

import Foundation
import Observation
import DeadEndsLib
import Parsing

/// Sink for report output.
//@Observable
//final class UIProgramOutput: ProgramOutput {
//    
//    @MainActor
//    var text: String = ""
//    
//    nonisolated func write(_ text: String) {
//        Task { @MainActor in
//            self.text += text
//        }
//    }
//    
//    @MainActor
//    func clear() {
//        text = ""
//    }
//}

//@Observable
//final class UIProgramOutput: ProgramOutput {
//
//    @MainActor var text: String = ""
//
//    private var pending = ""
//    private var flushScheduled = false
//
//    nonisolated func write(_ s: String) {
//        Task { @MainActor in
//            pending += s
//
//            guard !flushScheduled else { return }
//            flushScheduled = true
//
//            Task { @MainActor in
//                try? await Task.sleep(nanoseconds: 75_000_000) // 25 ms
//                text += pending
//                pending = ""
//                flushScheduled = false
//            }
//        }
//    }
//
//    @MainActor
//    func clear() {
//        text = ""
//        pending = ""
//        flushScheduled = false
//    }
//}

final class BufferedProgramOutput: ProgramOutput {
    private(set) var text: String = ""

    func write(_ s: String) {
        text += s
    }

    func clear() {
        text = ""
    }
}

//final class BufferedProgramOutput: ProgramOutput {
//    func clear() {
//        text = ""
//    }
//
//    private(set) var text = ""
//    private let maxChars = 100_000
//    private var truncated = false
//
//    func write(_ s: String) {
//        guard !truncated else { return }
//
//        if text.count + s.count <= maxChars {
//            text += s
//        } else {
//            let remaining = maxChars - text.count
//            if remaining > 0 {
//                text += s.prefix(remaining)
//            }
//            text += "\n\n[output truncated]"
//            truncated = true
//        }
//    }
//}

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
final class ProgramModel {

    var programName: String
    var source: String = ""  // Program source.
    var output = UIProgramOutput()
    //var output = ConsoleOutput()  // To allow debugging.

    var diagnostics: [Diagnostic] = []
    var parsedProgram: ParsedProgram? = nil
    var lastCompileSucceeded: Bool = false

    /// Create a program model with an unnamed empty source text.
    init(programName: String = "Untitled", source: String = "") {
        self.source = source
        self.programName = programName
    }

    /// Handle the compile button. This is the model operation that compiles
    /// a DeadEnds program that either succeeds or displays diagnostics.
    func compile() {

        diagnostics = []
        parsedProgram = nil
        output.clear()
        //output.text = ""

        guard !source.isEmpty else { return }
        do {  // In a do so we can get the diagnostics.
            let normalized = normalizedSource(source)
            var lexer = Lexer(source: normalized)  // Patch to handle smart quotes.
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
//    func run(database: Database) {
//
//        guard let parsedProgram else { return }
//        diagnostics = []
//        output.clear()
//        //output.text = ""
//        let program = Program(parsedProgram: parsedProgram, database: database, output: output)
//        do {
//            try program.interpretProgram()
//        } catch let error as RuntimeError {
//            diagnostics = [Diagnostic(message: error.description, line: nil)]
//        }
//        catch {
//            diagnostics = [Diagnostic(
//                message: String(describing: error),
//                line: nil
//            )]
//        }
//    }

    func run(database: Database) {
        guard let parsedProgram else { return }

        diagnostics = []
        output.clear()

        let buffer = BufferedProgramOutput()
        let program = Program(
            parsedProgram: parsedProgram,
            database: database,
            output: buffer
        )

        do {
            print("before interpret")
            try program.interpretProgram()
            print("after interpret, output size =", buffer.text.count)
            //output.text = buffer.text
            //output.text = "Program finished. Output size: \(buffer.text.count)"
            output.text = displayableOutput(buffer.text)
        } catch let error as RuntimeError {
            output.text = buffer.text
            diagnostics = [Diagnostic(message: error.description, line: 0)]
        } catch {
            output.text = buffer.text
            diagnostics = [Diagnostic(message: String(describing: error), line: 0)]
        }
    }
}

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
    default:
        return Diagnostic(
            message: "\(error)",
            line: nil
        )
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

func formatRuntimeError(_ error: RuntimeError) -> String {
    
    switch error {
    case .typeMismatch(let detail, let line): return detail
    case .invalidArguments(let detail, let line): return detail
    case .runtimeError(let detail, let line): return detail
    case .invalidSyntax(let detail, let line): return detail
    case .undefinedProcedure(let detail, let line): return detail
    case .undefinedFunction(let detail, let line): return detail
    case .undefinedSymbol(let detail, let line): return detail
    case .invalidControlFlow(let detail, let line): return detail
    case .executionFailed(let detail, let line): return detail
    case .argumentCount(let detail, let line): return detail
    case .typeError(let detail, let line): return detail
    case .missingDatabase(let detail, let line): return detail
    //case .syntax(let detail, let line): return detail
    //case .io(let detail, let line): return detail
    }
}

/// Required because TextEditor uses smart quotes that is
/// hard to turn off.
func normalizedSource(_ text: String) -> String {
    text
        .replacingOccurrences(of: "“", with: "\"")
        .replacingOccurrences(of: "”", with: "\"")
        .replacingOccurrences(of: "‘", with: "'")
        .replacingOccurrences(of: "’", with: "'")
}
