//
//  Program.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 20 March 2025.
//  Last changed on 21 April 2025.
//

import Foundation

// SymbolTable is an alias available for global and local symbol tables.
public typealias SymbolTable = [String: ProgramValue?]

// Program is the type of DeadEnds programs.
final public class Program {

    var builtins: [String: Builtin] = [:]

    // MARK: Static program properties
    let procedureTable: [String: ProgramNode] // Procedure definitions.
    let functionTable: [String: ProgramNode] // Function definitions.

    // MARK: Runtime program state.
    private(set) var globalSymbolTable: SymbolTable // Global variables.
    var database: Database? // Database
    private var callStack: [SymbolTable] = [[:]] // Runtime stack of symbol tables.

    // MARK: Computed properties.
    var localSymbolTable: SymbolTable { // Current symbol table (top of call stack).
        callStack.last ?? [:] // Should never be nil.
    }

    private var currentFrame: SymbolTable { // Needed to add to the symbol table nicely.
        get {
            guard let frame = callStack.last else { fatalError("No frame available") }
            return frame
        }
        set {
            guard !callStack.isEmpty else { fatalError("No frame available") }
            callStack[callStack.count - 1] = newValue
        }
    }

    // MARK: Initializer
    public init(procTable: [String : ProgramNode], funcTable: [String : ProgramNode], globalTable: SymbolTable,
         database: Database? = nil, callStack: [SymbolTable] = [[:]]) {
        self.procedureTable = procTable
        self.functionTable = funcTable
        self.globalSymbolTable = globalTable
        self.database = database
        self.callStack = callStack
        setupBuiltins()
    }

    // This allows the builtins to not worry about nil databases.
    var recordIndex: RecordIndex {
        guard let db = self.database else {
            fatalError("No database loaded — interpretation should not have started.")
        }
        return db.recordIndex
    }

    // MARK: Frame management.
    // pushCallFrame pushes a new local frame when a procedure or fuction is called.
    func pushCallFrame(_ frame: SymbolTable) {
        callStack.append(frame)
    }

    // popCallFrame pops the current frame when a procedure or function returns.
    func popCallFrame() {
        precondition(callStack.count > 1, "Cannot pop the global frame")
        callStack.removeLast()
    }

    // MARK: Symbol assignment.
    // lookupSymbol looks up a variable in the local symbol table, and if not there in the global table.
    func lookupSymbol(_ name: String) -> ProgramValue? {
        if let localValue = localSymbolTable[name] { // First look in the local symbol table.
            return localValue
        }
        if let globalValue = globalSymbolTable[name] { // Then look in the global symbol table.
            return globalValue
        }
        return nil // If not found.
    }

    // assignLocal assigns the value of an identifier to the local symbol table.
    func assignLocal(_ name: String, value: ProgramValue) {
        currentFrame[name] = value
    }

    // assignToSymbol udates or adds a new entry to the local or global symbol table.
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

// RunTimeError is the error thrown when errors are while interpreting a program.
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

// Extension to Program with the interpretProgram method begins the interpretation of a script program
extension Program {

    // Interpret the program by calling its entry procedure. The database must be passed in.
    @discardableResult
    public func interpretProgram(database: Database) throws -> InterpResult {
        self.database = database

        // Look for the entry procedure, normally 'main'.
        let entry = "main"
        guard let _ = procedureTable[entry] else {
            throw RuntimeError.undefinedProcedure("No '\(entry)' procedure found")
        }

        // Create a .procedureCall ProgramNode to the entry point and then call it.
        let mainProc = ProgramNode.procedureCall(name: entry, args: [])
        return try interpret(mainProc) // Top level return value can be ignored.
    }
}
