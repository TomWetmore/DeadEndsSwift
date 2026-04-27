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

/// DeadEnds program; combines static program parts with runtime parts.
final public class Program {

    let parsedProgram: ParsedProgram  // Immutable program.
    var builtins: [String: Builtin] = [:]  // Builtin library.
    let procTable: [String: Int]  // User defined procs.
    let funcTable: [String: Int]  // User defined funcs.
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
    public init(parsedProgram: ParsedProgram, database: Database, output: ProgramOutput) {

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
        self.procTable = procTable
        self.funcTable = funcTable
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
    //case syntax(_ detail: String, line: Int)
    //case io(_ detail: String, line: Int)

    public var description: String {
        switch self {
        case let .typeMismatch(m, l),
             let .invalidArguments(m, l),
             let .runtimeError(m, l),
             let .invalidSyntax(m, l),
             let .undefinedProcedure(m, l),
             let .undefinedFunction(m, l),
             let .undefinedSymbol(m, l),
             let .invalidControlFlow(m, l),
             let .executionFailed(m, l),
             let .argumentCount(m, l),
             let .typeError(m, l),
             let .missingDatabase(m, l):
            return "line \(l): \(m)"
        }
    }
}

/// Interpreter for interpretProgram method.
extension Program {

    /// Run the program by calling the main proc. This is the method that starts running
    /// a program.
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

/* TEST PROGRAM
 proc main ()
 {
     set(indi, indi(“@I1@“))
     list(ilist)
     list(alist)
     enqueue(ilist, indi)
     enqueue(alist, 1)
     while(indi, dequeue(ilist)) {
         set(ahnen, dequeue(alist))
         d(ahnen) ". " name(indi) nl()
         if (e, birth(indi)) { " if (e, death(indi)) { " if (par, father(indi)) {
             enqueue(ilist, par)
             enqueue(alist, mul(2,ahnen))
             “b. " long(e) nl() }
             “d. " long(e) nl() }
         }
     if (par,mother(indi)) {
         enqueue(ilist, par)
             enqueue(alist, add(1,mul(2,ahnen)))
     }
 }

 */
