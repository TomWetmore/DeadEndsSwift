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
    var output = UIProgramOutput()

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
        output.text = ""

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
    func run(database: Database) {

        guard let parsedProgram else { return }
        diagnostics = []
        output.text = ""
        let program = Program(parsedProgram: parsedProgram, database: database, output: output)
        do {
            try program.interpretProgram()
        } catch let error as RuntimeError {
            diagnostics = [Diagnostic(message: error.description, line: nil)]
        }
        catch {
            diagnostics = [Diagnostic(
                message: String(describing: error),
                line: nil
            )]
        }
    }
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
