//
//  Program.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 7 April 2026.
//  Last changed on 4 May 2026.
//

import Foundation

/// Generalize program output. Standard output, buffered output, and UI text view output
/// are used in DeadEnds.
public protocol ProgramOutput {

    func write(_ text: String)
}

public extension ProgramOutput {

    func writeln(_ text: String) {
        write(text + "\n")
    }
}

/// Program output for standard console output.
public final class ConsoleOutput: ProgramOutput {

    public func write(_ text: String) {
        print(text, terminator: "")
    }

    public init() {}  // Needed to make it public.
}

/// DeadEnds program; combines static program parts with runtime parts.
/// To run a DeadEnds program/script a program object is created and its
/// interpret program method is called.
final public class Program {

    let parsedProgram: ParsedProgram  // Immutable program.
    var builtins: [String: Builtin] = [:]  // Builtin library.
    let procTable: [String: ParsedProcDefn]  // User defined procs.
    let funcTable: [String: ParsedFuncDefn]  // User defined funcs.
    var hasRun = false
    var globalSymbolTable: SymbolTable = [:]  // Global symbols.
    var database: Database  // Database.
    let output: ProgramOutput  // Output sink.
    var callStack: [RuntimeFrame] = []  // Runtime stack.

    var recordIndex: RecordIndex { database.recordIndex }

    private var stepCount = 0
    private let maxSteps = 750_000

    /// Local symbol table, in the current frame.
    var localSymbolTable: SymbolTable {
        callStack.last?.symbols ?? [:]
    }

    /// Current frame in the run time stack.
    var currentFrame: RuntimeFrame {
        get {
            guard let frame = callStack.last else { fatalError("No frame available") }
            return frame
        }
        set {
            guard !callStack.isEmpty else { fatalError("No frame available") }
            callStack[callStack.count - 1] = newValue
        }
    }

    /// Create a runnable program from a parsed program, database, and output sink.
    public init(parsedProgram: ParsedProgram, database: Database, output: ProgramOutput) {

        self.parsedProgram = parsedProgram
        self.database = database
        self.output = output
        self.callStack  = [RuntimeFrame]()

        var procTable: [String: ParsedProcDefn] = [:]
        var funcTable: [String: ParsedFuncDefn] = [:]
        var globals: SymbolTable = [:]

        for defn in parsedProgram.defns {
            switch defn {
            case .procDef(let procDef):
                procTable[procDef.name] = procDef
            case .funcDef(let funcDef):
                funcTable[funcDef.name] = funcDef
            case .global(let globalDef):
                globals[globalDef.name] = .null
            }
        }
        self.procTable = procTable
        self.funcTable = funcTable
        self.globalSymbolTable = globals

        setupBuiltins()
    }
}

/// Run time errors that happen when a program is running.
public enum RuntimeError: Swift.Error, CustomStringConvertible {  // TODO: Remove "Swift." after fixing use of Error.

    case typeMismatch(_ detail: String, line: Int)
    case invalidArguments(_ detail: String, line: Int)
    case runtimeError(_ detail: String, line: Int)
    case invalidSyntax(_ detail: String, line: Int)
    case undefinedProcedure(_ detail: String, line: Int)
    case undefinedFunction(_ detail: String, line: Int)
    case undefinedSymbol(_ detail: String, line: Int)
    case invalidControlFlow(_ detail: String, line: Int)
    case executionFailed(_ detail: String, line: Int)
    case argumentCount(_ detail: String, line: Int)
    case typeError(_ detail: String, line: Int)
    case missingDatabase(_ detail: String, line: Int)

    public var message: String {
        switch self {
        case let .typeMismatch(m, _),
             let .invalidArguments(m, _),
             let .runtimeError(m, _),
             let .invalidSyntax(m, _),
             let .undefinedProcedure(m, _),
             let .undefinedFunction(m, _),
             let .undefinedSymbol(m, _),
             let .invalidControlFlow(m, _),
             let .executionFailed(m, _),
             let .argumentCount(m, _),
             let .typeError(m, _),
             let .missingDatabase(m, _):
            return m
        }
    }

    public var line: Int {
        switch self {
        case let .typeMismatch(_, l),
             let .invalidArguments(_, l),
             let .runtimeError(_, l),
             let .invalidSyntax(_, l),
             let .undefinedProcedure(_, l),
             let .undefinedFunction(_, l),
             let .undefinedSymbol(_, l),
             let .invalidControlFlow(_, l),
             let .executionFailed(_, l),
             let .argumentCount(_, l),
             let .typeError(_, l),
             let .missingDatabase(_, l):
            return l
        }
    }

    public var description: String {
        line > 0 ? "line \(line): \(message)" : message
    }
}

/// Interpreter for interpretProgram method.
extension Program {

    /// Run the program by calling its main procedure.
    @discardableResult
    public func interpretProgram() throws -> InterpResult {

        guard !hasRun else {  // TODO: Rethink the 'has run' idea.
            throw RuntimeError.runtimeError("programs can only be run once", line: 0)
        }
        hasRun = true
        let mainProc = try requireProcDefn("main", line: 0)
        if mainProc.params.count != 0 {
            throw RuntimeError.argumentCount("main: cannot have params", line: mainProc.line)
        }
        let mainCall = ParsedCallStatement(name: "main", args: [], line: 0)  // Bootstrap.
        return try interpProcCall(mainCall)
    }
}

/// Require methods for procedure and function definitions.
extension Program {

    /// Return a procedure defn or throw an undefined error.
    func requireProcDefn(_ name: String, line: Int) throws -> ParsedProcDefn {
        guard let procDefn = procTable[name] else {
            throw RuntimeError.undefinedProcedure("\(name): undefined procedure", line: line)
        }
        return procDefn
    }

    /// Return a function defn or throw an undefined error.
    func requireFuncDefn(_ name: String, line: Int) throws -> ParsedFuncDefn {
        guard let funcDefn = funcTable[name] else {
            throw RuntimeError.undefinedFunction("\(name): undefined function", line: line)
        }
        return funcDefn
    }
}

/// Infinite loop protection.
extension Program {

    /// Called when a statement is interpreted.
    func tick(line: Int) throws {
        stepCount += 1
        if stepCount > maxSteps {
            throw RuntimeError.runtimeError("run stopped: possible infinite loop", line: line)
        }
    }
}
