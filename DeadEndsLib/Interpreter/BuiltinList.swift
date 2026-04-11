//
//  BuiltinList.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 11 April 2026.
//  Last changed on 11 April 2026.
//

import Foundation


//
//  BuiltinList.swift
//  DeadEndsLib
//  This file has the builtin functions for the list data type
//
//  Created by Thomas Wetmore on 28 April 2025.
//  Last changed 28 April 2025.
//

import Foundation

extension Program {

    /// Declare an identifier to have a .list type.
    func builtinList(_ args: [ParsedExpr]) throws -> ProgramValue {
        let ident = try evaluate(args[0])
        guard case let .ident(varb) = ident else {
            throw RuntimeError.typeMismatch("Expected identifier for list")
        }
        let list = List<ProgramValue>.init()
        assignToSymbol(varb, value: .list(list))
        return .null

    }

    /// Return whether a list is empty.
    func builtinEmpty(_ args: [ParsedExpr]) throws -> ProgramValue {
        let list = try evaluateList(args[0], errMessage: "empty() expects a list argument")
        return list.count == 0 ? ProgramValue.trueProgramValue : ProgramValue.falseProgramValue
    }

    /// Return the length of a list.
    func builtinLength(_ args: [ParsedExpr]) throws -> ProgramValue {
        let list = try evaluateList(args[0], errMessage: "length() expects a list argument")
        return .integer(list.count)
    }

    /// Append a value to a list.
    func builtinAppend(_ args: [ParsedExpr]) throws -> ProgramValue {
        var list = try evaluateList(args[0], errMessage: "append() expects a list first argument")
        list.append(try evaluate(args[1]))
        return .null
    }

    /// Prepend a value to a list.
    func builtinPrepend(_ args: [ParsedExpr]) throws -> ProgramValue {
        var list = try evaluateList(args[0], errMessage: "append() expects a list first argument")
        list.prepend(try evaluate(args[1]))
        return .null
    }

    /// Remove the first value from a list.
    func builtinRemoveFirst(_ args: [ParsedExpr]) throws -> ProgramValue {
        var list = try evaluateList(args[0], errMessage: "removeFirst() expects a list argument")
        guard let first =  list.removeFirst() else { return .null }
        return first
    }

    /// Evaluate an expression and be sure it it s list.
    func evaluateList(_ node: ParsedExpr, errMessage: String) throws -> List<ProgramValue> {
        guard case let .list(list) = try evaluate(node) else {
            throw RuntimeError.typeMismatch(errMessage)
        }
        return list
    }
}

//forlist (LIST, ANY_V, INT_V) { } loop through all elements of list
// CONSIDER APPEND AND PREPEND

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
