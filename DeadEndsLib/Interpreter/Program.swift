//
//  Program.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 7 April 2026.
//  Last changed on 21 April 2026.
//

import Foundation

public typealias SymbolTable = [String: ProgramValue?]

/// Generalize program output.
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

/// DeadEnds program; combines static program parts with the runtime parts.
final public class Program {

    let parsedProgram: ParsedProgram  // Immutable program.
    var builtins: [String: Builtin] = [:]  // Builtin library.
    let procedureTable: [String: Int]  // User defined procs.
    let functionTable: [String: Int]  // User defined funcs.
    var hasRun = false
    private(set) var globalSymbolTable: SymbolTable = [:]  // Global symbols.
    var database: Database  // Database.
    let output: ProgramOutput  // Output sink.
    private var callStack: [SymbolTable] = [[:]]  // Runtime stack.

    var recordIndex: RecordIndex { database.recordIndex }

    /// Return the local symbol table, the current frame.
    var localSymbolTable: SymbolTable {
        callStack.last ?? [:]
    }

    /// The current frame; frame and symbol table are synonymous.
    private var currentFrame: SymbolTable {
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
    init(parsedProgram: ParsedProgram, database: Database, output: ProgramOutput) {

        self.parsedProgram = parsedProgram
        self.database = database
        self.output = output
        self.callStack = [[:]]

        /// Set up the tables
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
        self.procedureTable = procTable
        self.functionTable = funcTable
        self.globalSymbolTable = globals

        setupBuiltins()
    }

    /// Push a new local frame when a procedure or fuction is called.
    func pushCallFrame(_ frame: SymbolTable) {
        callStack.append(frame)
    }

    /// Pop the current frame when a procedure or function returns.
    func popCallFrame() {
        precondition(callStack.count > 1, "Cannot pop the global frame")
        callStack.removeLast()
    }

    /// Look up an identifier in the local symbol table, and if not
    /// there, in the global table.
    func lookupSymbol(_ name: String) -> ProgramValue? {

        if let localValue = localSymbolTable[name] {
            return localValue
        }
        if let globalValue = globalSymbolTable[name] {
            return globalValue
        }
        return nil // Not found.
    }

    /// Assign a value to an identifier in the local symbol table.
    func assignLocal(_ name: String, value: ProgramValue) {
        currentFrame[name] = value
    }

    /// Update or add a new entry to the local or global symbol table.
    /// If the identifier is in the local table, change its there, else
    /// if it is in the global table change it there, else add it to
    /// the local table.
    func assignToSymbol(_ name: String, value: ProgramValue) {

        if localSymbolTable[name] != nil {
            currentFrame[name] = value  // Update in local.
        } else if globalSymbolTable[name] != nil {
            globalSymbolTable[name] = value  // Update in global.
        } else {
            currentFrame[name] = value  // Add to local.
        }
    }
}

/// Run time errors that can happen when a program is running.
public enum RuntimeError: Swift.Error {  // TODO: Remove "Swift." after fixing incorrect use of Error.

    case typeMismatch(_ detail: String)
    case invalidArguments(_ detail: String)
    case runtimeError(_ detail: String)
    case invalidSyntax(_ detail: String)
    case undefinedProcedure(_ detail: String)
    case undefinedFunction(_ detail: String)
    case undefinedSymbol(_ detail: String)
    case invalidControlFlow(_ detail: String)
    case executionFailed(_ detail: String)
    case argumentCount(_ detail: String)
    case typeError(_ detail: String)
    case missingDatabase(_ detail: String)
    case syntax(_ detail: String)
    case io(_ detail: String)
}

/// Interpreter for interpretProgram method.
extension Program {

    /// Run the program by calling the main proc. This is method that begins the
    /// execution of a program.
    @discardableResult
    public func interpretProgram() throws -> InterpResult {
        guard !hasRun else {
            throw RuntimeError.runtimeError("Program objects may only be run once")
        }
        hasRun = true
        let mainProc = try procDefn("main")
        if mainProc.params.count != 0 {
            throw RuntimeError.argumentCount("Main proc cannot have parameters")
        }
        let mainCall = ParsedCallStatement(name: "main", args: [])  // Bootstrap.
        return try interpProcCall(mainCall)
    }
}

extension Program {

    /// Return a user proc definition.
    func procDefn(_ name: String) throws -> ParsedProcDefn {

        guard let index = procedureTable[name] else {
            throw RuntimeError.undefinedSymbol("proc '\(name)' is not found")
        }
        guard case .procDef(let procDef) = parsedProgram.defns[index] else {
            fatalError("Corrupt proc table for \(name)")
        }
        return procDef
    }

    /// Return a user func definition.
    func funcDefn(_ name: String) throws -> ParsedFuncDefn {
        
        guard let index = functionTable[name] else {
            throw RuntimeError.undefinedSymbol("func '\(name)' not found")
        }
        guard case .funcDef(let funcDef) = parsedProgram.defns[index] else {
            fatalError("Corrupt func table for \(name)")
        }
        return funcDef
    }
}
