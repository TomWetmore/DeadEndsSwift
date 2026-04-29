//
//  BuiltinList.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 11 April 2026.
//  Last changed on 28 April 2026.
//

import Foundation

/// Builtins are methods on Programs.
extension Program {

    /// Declare an identifier to have a .list type.
    func builtinList(_ args: [ParsedExpr]) throws -> ProgramValue {

        guard case let .identifier(varb) = args[0].kind else {
            throw RuntimeError.typeMismatch("list: arg to list must be an identifier", line: args[0].line)
        }
        let list = List<ProgramValue>()
        assignToSymbol(varb, value: .list(list))
        return .null
    }

    /// Return whether a list, table, person set or string is empty.
    func builtinEmpty(_ args: [ParsedExpr]) throws -> ProgramValue {

        switch try evaluate(args[0]) {
        case .list(let list):
            return list.count == 0 ? .trueProgramValue : .falseProgramValue
        case .table(let table):
            return table.count == 0 ? .trueProgramValue : .falseProgramValue
        case .indiset(let set):
            return set.count == 0 ? .trueProgramValue : .falseProgramValue
        case .string(let string):
            return string.isEmpty ? .trueProgramValue : .falseProgramValue
        default:
            throw RuntimeError.typeMismatch(
                "empty: arg must be a list, table, indiset, or string",
                line: args[0].line
            )
        }
    }

    /// Return the length of a list, table, person set or string.
    func builtinLength(_ args: [ParsedExpr]) throws -> ProgramValue {

        switch try evaluate(args[0]) {
        case .list(let list):
            return .integer(list.count)
        case .table(let table):
            return .integer(table.count)
        case .indiset(let set):
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
            try requireListVariable(args[0],errMessage: "append: 1st arg must be a list variable")
        list.append(try evaluate(args[1]))
        assignToSymbol(name, value: .list(list))
        return .null
    }

    /// Prepend a value to a list.
    func builtinPrepend(_ args: [ParsedExpr]) throws -> ProgramValue {
        var (name, list) =
            try requireListVariable(args[0], errMessage: "prepend: 1st arg must be a list variable")
        list.prepend(try evaluate(args[1]))
        assignToSymbol(name, value: .list(list))
        return .null
    }

    /// Remove the first value from a list.
    func builtinRemoveFirst(_ args: [ParsedExpr]) throws -> ProgramValue {
        var (name, list) =
            try requireListVariable(args[0], errMessage: "removefirst: 1st arg must be a list variable")
        guard let first = list.removeFirst() else { return .null }
        assignToSymbol(name, value: .list(list))
        return first
    }

    /// Evaluate an expression and be sure it is a list.
    private func evaluateList(_ expr: ParsedExpr, errMessage: String) throws -> List<ProgramValue> {
        guard case let .list(list) = try evaluate(expr) else {
            throw RuntimeError.typeMismatch(errMessage, line: expr.line)
        }
        return list
    }
}

//forlist (LIST, ANY_V, INT_V) { } loop through all elements of list


/// Structure that holds the programming language's List values.
public struct List<Element> {

    private var elements: [Element] = []

    var count: Int { elements.count }

    mutating func push(_ element: Element) {
        elements.insert(element, at: 0)
    }

    mutating func pop() -> Element? {
        guard !elements.isEmpty else { return nil }
        return elements.removeFirst()
    }

    mutating func enqueue(_ element: Element) {
        elements.append(element)
    }

    mutating func dequeue() -> Element? {
        guard !elements.isEmpty else { return nil }
        return elements.removeFirst()
    }

    mutating func append(_ element: Element) {
        elements.append(element)
    }

    mutating func prepend(_ element: Element) {
        elements.insert(element, at: 0)
    }

    mutating func removeFirst() -> Element? {
        guard !elements.isEmpty else { return nil }
        return self.elements.removeFirst()
    }

    subscript(index: Int) -> Element {
        get { elements[index] }
        set { elements[index] = newValue }
    }

    mutating func sort(by areInIncreasingOrder: (Element, Element) -> Bool) {
        elements.sort(by: areInIncreasingOrder)
    }
}

/// Needed to make List mappable.
extension List: Sequence {
    
    public func makeIterator() -> IndexingIterator<[Element]> {
        elements.makeIterator()
    }
}

/// Require a parsed expression to be an identifier; return it as a string.
//func evaluateIdent(_ expr: ParsedExpr, errMessage: String) throws -> String {
//    guard case let .identifier(name) = expr.kind else {
//        throw RuntimeError.typeMismatch(errMessage, line: expr.line)
//    }
//    return name
//}

extension Program {

    /// Convenience method for methods that need a modifiable list argument.
    func requireListVariable(_ expr: ParsedExpr, errMessage: String )
        throws -> (name: String, list: List<ProgramValue>) {

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

