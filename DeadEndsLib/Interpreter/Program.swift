//
//  Program.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 7 April 2026.
//  Last changed on 9 April 2026.
//

import Foundation

public typealias SymbolTable = [String: ProgramValue?]

// Program is the type of DeadEnds programs.
final public class Program {

    //var builtins: [String: Builtin] = [:]

    let procedureTable: [String: ParsedProcDef] // Procedure definitions.
    let functionTable: [String: ParsedFuncDef] // Function definitions.

    private(set) var globalSymbolTable: SymbolTable
    var database: Database? // Database
    private var callStack: [SymbolTable] = [[:]] // Runtime stack of symbol tables.

    var localSymbolTable: SymbolTable { // Symbol table at the top of the stack.
        callStack.last ?? [:] // Should never be nil.
    }

    /// The current frame. Note that frame and symbol table are near synonomous.
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

    /// Create a program from its proc, func, and global tables, and a database.
    init(procTable: [String : ParsedProcDef], funcTable: [String : ParsedFuncDef],
         globalTable: SymbolTable, database: Database? = nil,
         callStack: [SymbolTable] = [[:]]) {

        self.procedureTable = procTable
        self.functionTable = funcTable
        self.globalSymbolTable = globalTable
        self.database = database
        self.callStack = callStack
        //setupBuiltins()
    }

    // Allow the builtins to not worry about nil databases.
    var recordIndex: RecordIndex {
        guard let db = self.database else {
            fatalError("No database loaded — interpretation impossible.")
        }
        return db.recordIndex
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
        guard let mainProc = procedureTable["main"] else {
            throw RuntimeError.undefinedProcedure("No main procedure found")
        }
        if mainProc.params.count != 0 {
            throw RuntimeError.argumentCount("Main proc cannot have parameters")
        }
        // Create a bootstrap ParsedCallStmt for main and call it.
        let mainCall = ParsedCallStmt(name: "main", args: [])
        return try interpProcCall(mainCall)
    }
}
