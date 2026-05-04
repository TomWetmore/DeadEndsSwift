//
//  Program.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 7 April 2026.
//  Last changed on 3 May 2026.
//

import Foundation

/// Generalize program output.
public protocol ProgramOutput {
    func write(_ text: String)

    func clear()
}

public extension ProgramOutput {
    func writeln(_ text: String) {
        write(text + "\n")
    }
}

/// Program output for standard console output.
public final class ConsoleOutput: ProgramOutput {

    public var text: String = ""

    public func write(_ text: String) {
        print(text, terminator: "")
    }

    public init() {}  // Needed to make it public.

    public func clear() {}  // Clear is a no-op for this meeter of the protocol.
}

/// DeadEnds program; combines static program parts with runtime parts.
final public class Program {

    let parsedProgram: ParsedProgram  // Immutable program.
    var builtins: [String: Builtin] = [:]  // Builtin library.
    let procTable: [String: Int]  // User defined procs.
    let funcTable: [String: Int]  // User defined funcs.
    var hasRun = false
    var globalSymbolTable: SymbolTable = [:]  // Global symbols.
    var database: Database  // Database.
    let output: ProgramOutput  // Output sink.
    var callStack: [RuntimeFrame] = []  // Runtime stack.

    var recordIndex: RecordIndex { database.recordIndex }

    var localSymbolTable: SymbolTable {
        callStack.last?.symbols ?? [:]
    }

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

    /// Create a runnable program from a parsed program.
    public init(parsedProgram: ParsedProgram, database: Database, output: ProgramOutput) {

        self.parsedProgram = parsedProgram
        self.database = database
        self.output = output
        self.callStack  = [RuntimeFrame]()

        var procTable: [String: Int] = [:]
        var funcTable: [String: Int] = [:]
        var globals: SymbolTable = [:]

        for (i, defn) in parsedProgram.defns.enumerated() {
            switch defn {
            case .procDef(let procDef):
                procTable[procDef.name] = i
            case .funcDef(let funcDef):
                funcTable[funcDef.name] = i
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
public enum RuntimeError: Swift.Error, CustomStringConvertible {  // TODO: Remove "Swift." after fixing incorrect use of Error.

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

    /// Run a program by calling the main proc.
    @discardableResult
    public func interpretProgram() throws -> InterpResult {
        guard !hasRun else {
            throw RuntimeError.runtimeError("programs can only be run once",
                                            line: 0)  // Line 0 okay.
        }
        hasRun = true
        guard let mainIndex = procTable["main"] else {
            throw RuntimeError.undefinedProcedure("no main proc found", line: 0)
        }
        guard case .procDef(let mainProc) = parsedProgram.defns[mainIndex] else {
            fatalError("corrupt proc table for main")
        }
        if mainProc.params.count != 0 {
            throw RuntimeError.argumentCount("main proc cannot have params",
                                             line: mainProc.line)
        }
        let mainCall = ParsedCallStatement(name: "main", args: [], line: 0)  // Bootstrap.
        return try interpProcCall(mainCall)
    }
}

extension Program {

    /// Return a user proc definition. The proc table maps proc names to integers.
    /// This method gets the number from the name and then gets the definitioin
    /// by subscripting the defns list in the parsed program,
    func procDefn(_ name: String, line: Int) throws -> ParsedProcDefn {

        guard let index = procTable[name] else {
            throw RuntimeError.undefinedSymbol("proc '\(name)' is not found",
                                               line: line)
        }
        guard case .procDef(let procDef) = parsedProgram.defns[index] else {
            fatalError("corrupt proc table for \(name)")
        }
        return procDef
    }

    /// Return a user func definition. The func table maps names to integers.
    /// This method looks up the number from the name and then gets the
    /// definition by subscripting the list of definitions in the parsed program.
    func funcDefn(_ name: String, line: Int) throws -> ParsedFuncDefn {

        guard let index = funcTable[name] else {
            throw RuntimeError.undefinedSymbol("func '\(name)' not found",
                                               line: line)
        }
        guard case .funcDef(let funcDef) = parsedProgram.defns[index] else {
            fatalError("Corrupt func table for \(name)")
        }
        return funcDef
    }
}

/// INFINITE LOOP DETECTION.
nonisolated(unsafe) private var stepCount = 0
private let maxSteps = 100_000

func tick(line: Int) throws {
    stepCount += 1
    if stepCount > maxSteps {
        throw RuntimeError.runtimeError(
            "execution stopped: possible infinite loop",
            line: line
        )
    }
}

