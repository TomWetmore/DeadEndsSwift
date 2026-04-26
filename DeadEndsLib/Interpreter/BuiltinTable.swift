//
//  BuiltinTable.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 16 April 2026.
//  Last changed on 26 April 2026.
//

import Foundation

final public class ProgramTable {
    var elements: [String: ProgramValue] = [:]
}

extension Program {

    /// Create a program table and add it to the symbol table.
    func builtinTable(_ args: [ParsedExpr]) throws -> ProgramValue {
        guard case let .identifier(name) = args[0].kind else {
            throw RuntimeError.typeError("table: arg must be identifier",
                                         line: args[0].line)
        }
        assignToSymbol(name, value: .table(ProgramTable()))
        return .null
    }

    /// Insert a new entry in a program table.
    func builtinInsert(_ args: [ParsedExpr]) throws -> ProgramValue {
        let tableValue = try evaluate(args[0])
        guard case let .table(table) = tableValue else {
            throw RuntimeError.typeError("insert: 1st arg must be a table",
                                         line:args[0].line)
        }
        let keyValue = try evaluate(args[1])
        guard case let .string(key) = keyValue else {
            throw RuntimeError.typeError("insert: 2nd arg must be a string",
                                         line: args[1].line)
        }
        let value = try evaluate(args[2])
        table.elements[key] = value
        return .null
    }

    /// Lookup an entry in a program table.
    func builtinLookup(_ args: [ParsedExpr]) throws -> ProgramValue {
        let tableValue = try evaluate(args[0])
        guard case let .table(table) = tableValue else {
            throw RuntimeError.typeError("lookup: 1st arg must be a table",
                                         line: args[0].line)
        }
        let keyValue = try evaluate(args[1])
        guard case let .string(key) = keyValue else {
            throw RuntimeError.typeError("lookup: 2nd arg must be a string",
                                         line: args[1].line)
        }
        return table.elements[key] ?? .null
    }
}
