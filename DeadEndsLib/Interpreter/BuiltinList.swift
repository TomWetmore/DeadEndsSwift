//
//  BuiltinList.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 11 April 2026.
//  Last changed on 6 May 2026.
//

import Foundation

/// Builtins are methods on Programs.
extension Program {

    /// Return an empty list.
    func builtinList(_ args: [ParsedExpr]) throws -> ProgramValue {
        return .list(List())
    }

    /// Return whether a list, table, person set or string is empty.
    func builtinEmpty(_ args: [ParsedExpr]) throws -> ProgramValue {

        switch try evaluate(args[0]) {
        case .list(let list):
            return list.count == 0 ? .trueProgramValue : .falseProgramValue
        case .table(let table):
            return table.count == 0 ? .trueProgramValue : .falseProgramValue
        case .personset(let set):
            return set.count == 0 ? .trueProgramValue : .falseProgramValue
        case .string(let string):
            return string.isEmpty ? .trueProgramValue : .falseProgramValue
        default:
            throw RuntimeError.typeMismatch(
                "empty: arg must be a list, table, personset, or string",
                line: args[0].line
            )
        }
    }

    /// Clear the contents of a list, table, or person set.
    func builtinClear(_ args: [ParsedExpr]) throws -> ProgramValue {

        guard case let .identifier(name) = args[0].kind else {
            throw RuntimeError.typeMismatch(
                "clear: arg must be a list, table, or indiset variable",
                line: args[0].line
            )
        }
        guard let value = lookupSymbol(name) else {
            throw RuntimeError.undefinedSymbol(
                "undefined variable: \(name)",
                line: args[0].line
            )
        }
        switch value {
        case .list(var list):
            list.clear()
            assignToSymbol(name, value: .list(list))
        case .table(let table):
            table.clear()
            assignToSymbol(name, value: .table(table))
        case .personset(let personset):
            personset.clear()
            assignToSymbol(name, value: .personset(personset))
        default:
            throw RuntimeError.typeMismatch(
                "clear: arg must be a list, table, or indiset variable",
                line: args[0].line
            )
        }
        return .null
    }

    /// Return the length of a list, table, person set or string.
    func builtinLength(_ args: [ParsedExpr]) throws -> ProgramValue {

        switch try evaluate(args[0]) {
        case .list(let list):
            return .integer(list.count)
        case .table(let table):
            return .integer(table.count)
        case .personset(let set):
            return .integer(set.count)
        case .string(let string):
            return .integer(string.count)
        default:
            throw RuntimeError.typeMismatch("length: arg must be a list, table, indiset, or string",
                                            line: args[0].line)
        }
    }

    /// Append a value to a list.
    func builtinAppend(_ args: [ParsedExpr]) throws -> ProgramValue {
        var (name, list) =
            try requireListVariable(args[0], errMessage: "append: 1st arg must be a list var")
        list.append(try evaluate(args[1]))
        assignToSymbol(name, value: .list(list))
        return .null
    }

    /// Prepend a value to a list.
    func builtinPrepend(_ args: [ParsedExpr]) throws -> ProgramValue {
        var (name, list) =
            try requireListVariable(args[0], errMessage: "prepend: 1st arg must be a list var")
        list.prepend(try evaluate(args[1]))
        assignToSymbol(name, value: .list(list))
        return .null
    }

    /// Remove the first value from a list.
    func builtinRemoveFirst(_ args: [ParsedExpr]) throws -> ProgramValue {
        var (name, list) =
            try requireListVariable(args[0], errMessage: "removefirst: 1st arg must be a list var")
        guard let first = list.removeFirst() else { return .null }
        assignToSymbol(name, value: .list(list))
        return first
    }

    /// Evaluate an expression and be sure it is a list.
    func evaluateList(_ expr: ParsedExpr, errMessage: String) throws -> List {
        guard case let .list(list) = try evaluate(expr) else {
            throw RuntimeError.typeMismatch(errMessage, line: expr.line)
        }
        return list
    }
}

/// Structure that holds the programming language's List values.
public struct List {

    private var values: [ProgramValue] = []

    var count: Int { values.count }

    public init(_ values: [ProgramValue] = []) {
        self.values = values
    }

    mutating func push(_ element: ProgramValue) {
        values.insert(element, at: 0)
    }

    mutating func pop() -> ProgramValue? {
        guard !values.isEmpty else { return nil }
        return values.removeFirst()
    }

    mutating func enqueue(_ element: ProgramValue) {
        values.append(element)
    }

    mutating func dequeue() -> ProgramValue? {
        guard !values.isEmpty else { return nil }
        return values.removeFirst()
    }

    mutating func append(_ element: ProgramValue) {
        values.append(element)
    }

    mutating func prepend(_ element: ProgramValue) {
        values.insert(element, at: 0)
    }

    mutating func removeFirst() -> ProgramValue? {
        guard !values.isEmpty else { return nil }
        return self.values.removeFirst()
    }

    mutating func clear() {
        values.removeAll(keepingCapacity: false)
    }

    subscript(index: Int) -> ProgramValue {
        get { values[index] }
        set { values[index] = newValue }
    }

    mutating func sort(by areInIncreasingOrder: (ProgramValue, ProgramValue) -> Bool) {
        values.sort(by: areInIncreasingOrder)
    }
}

/// Needed to make List mappable.
extension List: Sequence {
    
    public func makeIterator() -> IndexingIterator<[ProgramValue]> {
        values.makeIterator()
    }
}

extension Program {

    /// Convenience method for methods that need a modifiable list argument.
    func requireListVariable(_ expr: ParsedExpr, errMessage: String )
        throws -> (name: String, list: List) {

        guard case let .identifier(name) = expr.kind else {
            throw RuntimeError.typeMismatch(errMessage, line: expr.line)
        }
        guard let value = lookupSymbol(name) else {
            throw RuntimeError.undefinedSymbol("undefined variable: \(name)", line: expr.line)
        }
        guard case let .list(list) = value else {
            throw RuntimeError.typeMismatch(errMessage, line: expr.line)
        }

        return (name, list)
    }
}
