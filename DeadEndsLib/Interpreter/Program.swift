//
//  Program.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 7 April 2026.
//  Last changed on 13 October 2026.
//

import Foundation

/// A Program combines static program parts with runtime parts.
///
/// To run a DeadEnds Program create a Program object and then call its
/// main procedure.
///
@MainActor
final public class Program {

    var builtins: [String: Builtin] = [:]  // Built-in library.
    let procTable: [String: ParsedProcDefn]  // User defined procs.
    let funcTable: [String: ParsedFuncDefn]  // User defined funcs.
    var globalSymbolTable: SymbolTable = [:]  // Global symbols.
    var database: Database  // Database.
    let output: ProgramOutput  // Program output sink.
    let userInterface: UserInterface // Program UI channel.
    var callStack: [RuntimeFrame] = []  // Runtime stack.
    private let timerOrigin = ContinuousClock.now  // Time when Program is created.

    var recordIndex: RecordIndex { database.recordIndex }

    var stepCount = 0  // Counts number of statements interpreted.
    private let maxSteps = 100_000_000  // TODO: Remove?

    var localSymbolTable: SymbolTable { // Symbol table in current frame.
        callStack.last?.symbols ?? [:]
    }

    /// Current frame in the run time stack.

    var currentFrame: RuntimeFrame {

        get {
            guard let frame = callStack.last else {
                fatalError("No frame available")
            }
            return frame
        }
        set {
            guard !callStack.isEmpty else {
                fatalError("No frame available")
            }
            callStack[callStack.count - 1] = newValue
        }
    }

    /// Create a runnable Program from a ParsedProgram, Database, ProgramOutput,
    /// and UserInterface.
    ///
    public init(parsedProgram: ParsedProgram, database: Database,
                output: ProgramOutput, userInterface: UserInterface) {

        self.database = database
        self.output = output
        self.userInterface = userInterface
        self.callStack  = [RuntimeFrame]()

        var procTable: [String: ParsedProcDefn] = [:]
        var funcTable: [String: ParsedFuncDefn] = [:]
        var globals: SymbolTable = [:]
        var includes: [String] = []

        for defn in parsedProgram.defns {

            switch defn {

            case .procDefn(let procDef):
                procTable[procDef.name] = procDef

            case .funcDefn(let funcDef):
                funcTable[funcDef.name] = funcDef

            // Add identifier to the global SymbolTable with a .null value.
            case .global(let globalDef):
                globals[globalDef.name] = .null

            // In the final version these will have been consumed.
            case .include(let includeFile):
                includes.append(includeFile.name)
            }
        }
        self.procTable = procTable
        self.funcTable = funcTable
        self.globalSymbolTable = globals

        // Create the array of builtins with the current Program in their closures.
        // Because of the approach used here, a separate array is needed for every
        // Program.
        setupBuiltins()
    }
}

extension Program {

    /// Return the elapsed time since this Program was created.
    ///
    public var timerValue: Double {

        let duration = timerOrigin.duration(to: ContinuousClock.now)
        let components = duration.components

        return Double(components.seconds) +
            Double(components.attoseconds) / 1.0e18
    }
}

/// Generalize program output. Standard output, buffered output, and UI text view output
/// are used in DeadEnds.

public protocol ProgramOutput {

    func write(_ text: String)

    @MainActor
    func flush() async  // Ensure buffered output is visible.
}

public extension ProgramOutput {

    func writeLine(_ text: String) {
        write(text + "\n")
    }
}

/// Program output for standard console output.

public final class ConsoleOutput: ProgramOutput {

    /// The program output channel uses standard output. (The program UI channel uses
    /// standard error.)

    public func write(_ string: String) {
        FileHandle.standardOutput.write(Data(string.utf8))
    }

    @MainActor public func flush() async {}

    public init() {}  // Needed to make it public.
}

/// Run time errors.
///
public struct RuntimeError: Error, CustomStringConvertible {

    public let message: String
    public let line: Int

    public init(_ message: String, line: Int = 0) {
        self.message = message
        self.line = line
    }

    public var description: String {
        line > 0 ? "line \(line): \(message)" : message
    }
}

/// Interpreter for the main procedure.
///
extension Program {

    /// Run the Program by calling its main procedure.
    @discardableResult
    public func interpretProgram() async throws -> InterpResult {

        let mainCall = ParsedCallStatement(name: "main", args: [], line: 0)
        return try await interpProcCall(mainCall)
    }
}

/// Require methods for procedure and function definitions.
extension Program {

    /// Return a procedure defn or throw an undefined error.
    func requireProcDefn(_ name: String, line: Int) throws -> ParsedProcDefn {
        guard let procDefn = procTable[name] else {
            throw RuntimeError("\(name): undefined procedure", line: line)
        }
        return procDefn
    }

    /// Return a function defn or throw an undefined error.
    func requireFuncDefn(_ name: String, line: Int) throws -> ParsedFuncDefn {

        guard let funcDefn = funcTable[name] else {
            throw RuntimeError("\(name): undefined function", line: line)
        }
        return funcDefn
    }
}

/// Infinite loop protection.
extension Program {

    /// Called when a statement is interpreted.
    func tick(line: Int) async throws {

        stepCount += 1
        if stepCount % 6000 == 0 { await output.flush() }
        if stepCount > maxSteps {
            throw RuntimeError("run stopped: possible infinite loop", line: line)
        }
    }
}
