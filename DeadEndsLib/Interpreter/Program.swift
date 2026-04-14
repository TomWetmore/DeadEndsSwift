//
//  Program.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 7 April 2026.
//  Last changed on 9 April 2026.
//

import Foundation

public typealias SymbolTable = [String: ProgramValue?]

/// DeadEnds program; Combines the static program parts with the run time parts.
final public class Program {

    let parsedProgram: ParsedProgram  // The static, immutable program.
    var builtins: [String: Builtin] = [:]  // The table of builtin library functions.
    let procedureTable: [String: Int]  // User defined procedures.
    let functionTable: [String: Int]  // User defined functions.

    private(set) var globalSymbolTable: SymbolTable  // Global symbol table.
    var database: Database?  // Database
    private var callStack: [SymbolTable] = [[:]]  // Run time stack.

    var recordIndex: RecordIndex {
        guard let db = self.database else {
            fatalError("No database loaded — interpretation impossible.")
        }
        return db.recordIndex
    }

    var localSymbolTable: SymbolTable {
        callStack.last ?? [:]
    }

    /// The current frame. Note that frame and symbol table are near synonymous.
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

    /// Create a run time program from a parsed program.
    init(parsedProgram: ParsedProgram, database: Database? = nil,
         callStack: [SymbolTable] = [[:]]) {

        self.parsedProgram = parsedProgram
        self.database = database
        self.callStack = callStack

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
    /// If the identifier is in the local table, change its value, else
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
public enum RuntimeError: Swift.Error {  // TODO: Remove "Swift." after fixing the over use of Error.

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

/// Extension to Program with the interpretProgram method/
extension Program {

    /// Run the program by calling the main procedure. procedure.
    @discardableResult
    public func interpretProgram(database: Database) throws -> InterpResult {
        self.database = database
        // Get the main procedure.
        let mainProc = try procDefn("main")
        if mainProc.params.count != 0 {
            throw RuntimeError.argumentCount("Main proc cannot have parameters")
        }
        // Create a bootstrap ParsedCallStmt for main and call it.
        let mainCall = ParsedCallStatement(name: "main", args: [])
        return try interpProcCall(mainCall)
    }
}

extension Program {

    /// Return the definition of a user procedure.
    func procDefn(_ name: String) throws -> ParsedProcDefn {
        guard let index = procedureTable[name] else {
            throw RuntimeError.undefinedSymbol("Proc '\(name)' is not found")
        }
        guard case .procDef(let procDef) = parsedProgram.defns[index] else {
            fatalError("Corrupt procedure table for \(name)")
        }
        return procDef
    }

    /// Return the definition of a user function.
    func funcDefn(_ name: String) throws -> ParsedFuncDefn {
        guard let index = procedureTable[name] else {
            throw RuntimeError.undefinedSymbol("Function '\(name)' not found")
        }
        guard case .funcDef(let funcDef) = parsedProgram.defns[index] else {
            fatalError("Corrupt funcion table for \(name)")
        }
        return funcDef
    }
}
