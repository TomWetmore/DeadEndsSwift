//
//  BuiltinTable.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 16 April 2026.
//  Last changed on 24 April 2026.
//

import Foundation

final public class ProgramTable {
    var elements: [String: ProgramValue] = [:]
}

extension Program {

    /// Create a program table and add it to the symbol table.
    func builtinTable(_ args: [ParsedExpr]) throws -> ProgramValue {
        guard case let .identifier(name) = args[0] else {
            throw RuntimeError.typeError("table() expects an identifier", line: 0)
        }
        assignToSymbol(name, value: .table(ProgramTable()))
        return .null
    }

    /// Insert a new entry in a program table.
    func builtinInsert(_ args: [ParsedExpr]) throws -> ProgramValue {
        let tableValue = try evaluate(args[0])
        guard case let .table(table) = tableValue else {
            throw RuntimeError.typeError("insert() first arg must evaluate to a table", line: 0)
        }
        let keyValue = try evaluate(args[1])
        guard case let .string(key) = keyValue else {
            throw RuntimeError.typeError("insert() second arg must evaluate to a string", line: 0)
        }
        let value = try evaluate(args[2])
        table.elements[key] = value
        return .null
    }

    /// Lookup an entry in a program table.
    func builtinLookup(_ args: [ParsedExpr]) throws -> ProgramValue {
        let tableValue = try evaluate(args[0])
        guard case let .table(table) = tableValue else {
            throw RuntimeError.typeError("lookup() first arg must evaluate to a table", line: 0)
        }
        let keyValue = try evaluate(args[1])
        guard case let .string(key) = keyValue else {
            throw RuntimeError.typeError("lookup() second arg must evaluate to a string", line: 0)
        }
        return table.elements[key] ?? .null
    }
}
