//
//  BuiltinTable.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 16 April 2026.
//  Last changed on 12 May 2026.
//

import Foundation

/// Underlying dictionary used for the program value data type.
final public class ProgramTable {
    
    var elements: [String: ProgramValue] = [:]

    var count: Int {
        elements.count
    }

    func clear() {
        elements.removeAll(keepingCapacity: true)
    }
}

extension Program {

    /// Create a program table and add it to the symbol table.
    func bltinTable(_ args: [ParsedExpr]) throws -> ProgramValue {
        return .table(ProgramTable())
    }

    /// Insert a new entry in a program table.
    func bltinInsert(_ args: [ParsedExpr]) throws -> ProgramValue {
        let tableValue = try evaluate(args[0])
        guard case let .table(table) = tableValue else {
            throw RuntimeError("insert: 1st arg must be a table", line:args[0].line)
        }
        let keyValue = try evaluate(args[1])
        guard case let .string(key) = keyValue else {
            throw RuntimeError("insert: 2nd arg must be a string", line: args[1].line)
        }
        let value = try evaluate(args[2])
        table.elements[key] = value
        return .null
    }

    /// Lookup an entry in a program table.
    func bltinLookup(_ args: [ParsedExpr]) throws -> ProgramValue {
        let tableValue = try evaluate(args[0])
        guard case let .table(table) = tableValue else {
            throw RuntimeError("lookup: 1st arg must be a table", line: args[0].line)
        }
        let keyValue = try evaluate(args[1])
        guard case let .string(key) = keyValue else {
            throw RuntimeError("lookup: 2nd arg must be a string", line: args[1].line)
        }
        return table.elements[key] ?? .null
    }

    /// TODO: Isn't this redundant with the generic length builtin?
    func builtinTableLength(_ args: [ParsedExpr]) throws -> ProgramValue {
        let tableValue = try evaluate(args[0])
        guard case let .table(table) = tableValue else {
            throw RuntimeError("table-length: 1st arg must be a table", line: args[0].line)
        }
        return .integer(table.elements.count)
    }
}
