//
//  Frame.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 27 April 2026.
//  Last changed on 28 April 2026.
//

import Foundation

public typealias SymbolTable = [String : ProgramValue?]

enum RoutineKind: String {

    case proc
    case function
}

/// Frames on the run time stack.
struct RuntimeFrame {

    let name: String  // Name of proc or func.
    let kind: RoutineKind  // Whether proc or func.
    let defnLine: Int  // Line where defined.
    let callLine: Int  // Line where calling.
    let params: [String]  // Params as strings.
    var symbols: SymbolTable  // Local symbol table.
}

extension Program {

    /// Push a new local frame when a procedure or function is called.
    func pushCallFrame(_ frame: RuntimeFrame) {
        callStack.append(frame)
    }

    /// Pop the current frame when a procedure or function returns.
    func popCallFrame() {
        precondition(!callStack.isEmpty, "Cannot pop empty call stack")
        callStack.removeLast()
    }

    /// Look up an identifier in the local symbol table; if not there try
    /// the global table.
    func lookupSymbol(_ name: String) -> ProgramValue? {
        if let localValue = callStack.last?.symbols[name] {
            return localValue
        }
        if let globalValue = globalSymbolTable[name] {
            return globalValue
        }
        return nil
    }

    /// Assign a value to an identifier in the local symbol table.
    func assignLocal(_ name: String, value: ProgramValue) {
        guard !callStack.isEmpty else {
            fatalError("No frame available")
        }
        callStack[callStack.count - 1].symbols[name] = value
    }

    /// Update or add a new entry to the local or global symbol table.
    func assignToSymbol(_ name: String, value: ProgramValue) {

        guard !callStack.isEmpty else {
            fatalError("No frame available")
        }
        if callStack.last!.symbols[name] != nil {
            callStack[callStack.count - 1].symbols[name] = value
        } else if globalSymbolTable[name] != nil {
            globalSymbolTable[name] = value
        } else {
            callStack[callStack.count - 1].symbols[name] = value
        }
    }
}
