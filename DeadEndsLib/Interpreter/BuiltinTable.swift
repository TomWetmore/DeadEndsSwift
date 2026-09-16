//
//  BuiltinTable.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 16 April 2026.
//  Last changed on 16 September 2026.
//

import Foundation

/// Class used as the DeadEnds language table datatype. It maps strings
/// to program values.
final public class TableValue {

    /// Elements of the table.
    var elements: [String: ProgramValue] = [:]

    /// Number of elements in the table.
    var count: Int {
        elements.count
    }

    /// Empty the table.
    func clear() {
        elements.removeAll(keepingCapacity: true)
    }
}

/// Built-in functions that implement the table data type.
extension Program {

    /// Create an empty table program value.
    /// table() -> table
    func bltinTable(_ args: [ParsedExpr]) throws -> ProgramValue {

        return .table(TableValue())
    }

    /// Insert an entry into a table. There are no restrictions on values.
    /// insert(table, string, any) -> table
    func bltinInsert(_ args: [ParsedExpr]) async throws -> ProgramValue {

        guard case let .table(table) = try await evaluate(args[0]) else {
            throw RuntimeError("insert: 1st arg must be a table", line:args[0].line)
        }
        guard case let .string(key) = try await evaluate(args[1]) else {
            throw RuntimeError("insert: 2nd arg must be a string", line: args[1].line)
        }
        table.elements[key] = try await evaluate(args[2])
        return .table(table)
    }

    /// Lookup an entry in a program table, returning its value if present.
    /// lookup(table, string) -> any|null
    func bltinLookup(_ args: [ParsedExpr]) async throws -> ProgramValue {

        guard case let .table(table) = try await evaluate(args[0]) else {
            throw RuntimeError("lookup: 1st arg must be a table", line: args[0].line)
        }
        guard case let .string(key) = try await evaluate(args[1]) else {
            throw RuntimeError("lookup: 2nd arg must be a string", line: args[1].line)
        }
        return table.elements[key] ?? .null
    }

    /// Determine if a program table contains an entry with a key.
    /// contains(table, string) -> bool
    func bltinContains(_ args: [ParsedExpr]) async throws -> ProgramValue {

        guard case let .table(table) = try await evaluate(args[0]) else {
            throw RuntimeError("contains: 1st arg must be a table", line: args[0].line)
        }
        guard case let .string(key) = try await evaluate(args[1]) else {
            throw RuntimeError("contains: 2nd arg must be a key", line: args[1].line)
        }
        return .boolean(table.elements.keys.contains(key))
    }
}
