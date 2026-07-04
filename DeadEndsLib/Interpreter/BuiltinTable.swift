//
//  BuiltinTable.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 16 April 2026.
//  Last changed on 4 July 2026.
//

import Foundation

/// Dictionary used as the DeadEnds program table data type; it maps strings
/// to program values.
final public class ProgramTable {
    
    var elements: [String: ProgramValue] = [:]  // Underlying dictionary.

    var count: Int { elements.count }  // Number of dictionary entries.

    /// Empty the table.
    func clear() {
        elements.removeAll(keepingCapacity: true)
    }
}

/// Built-in functions that implement the table user interface.
extension Program {

    /// Create an empty table program value.
    func bltinTable(_ args: [ParsedExpr]) throws -> ProgramValue {
        return .table(ProgramTable())
    }

    /// Insert an entry into a table. There are no restrinctions on values.
    func bltinInsert(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let tableValue = try await evaluate(args[0])
        guard case let .table(table) = tableValue else {
            throw RuntimeError("insert: 1st arg must be a table", line:args[0].line)
        }
        let keyValue = try await evaluate(args[1])
        guard case let .string(key) = keyValue else {
            throw RuntimeError("insert: 2nd arg must be a string", line: args[1].line)
        }
        let value = try await evaluate(args[2])
        table.elements[key] = value
        return .table(table)
    }

    /// Lookup an entry in a program tablel, returning its value if present.
    func bltinLookup(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let tableValue = try await evaluate(args[0])
        guard case let .table(table) = tableValue else {
            throw RuntimeError("lookup: 1st arg must be a table", line: args[0].line)
        }
        let keyValue = try await evaluate(args[1])
        guard case let .string(key) = keyValue else {
            throw RuntimeError("lookup: 2nd arg must be a string", line: args[1].line)
        }
        return table.elements[key] ?? .null
    }
}
