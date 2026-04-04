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

    // builtinList declares a variable to be a .list type.
    func builtinList(_ args: [ProgramNode]) throws -> ProgramValue {
        let ident = try evaluateIdent(args[0])
        guard case let .string(varb) = ident else {
            throw RuntimeError.typeMismatch("Expected string identifier for list")
        }
        let list = List<ProgramValue>.init()
        assignToSymbol(varb, value: .list(list))
        return .null

    }

    // builtinEmpty returns whether a list is empty.
    func builtinEmpty(_ args: [ProgramNode]) throws -> ProgramValue {
        let list = try evaluateList(args[0], errMessage: "empty() expects a list argument")
        return list.count == 0 ? ProgramValue.trueProgramValue : ProgramValue.falseProgramValue
    }

    // builtinLength returns the length of a list.
    func builtinLength(_ args: [ProgramNode]) throws -> ProgramValue {
        let list = try evaluateList(args[0], errMessage: "length() expects a list argument")
        return .integer(list.count)
    }

    // builtinAppend appends a ProgramValue to a list.
    // If the new element is a string PValue the list becomes the owner of that string.
    func builtinAppend(_ args: [ProgramNode]) throws -> ProgramValue {
        var list = try evaluateList(args[0], errMessage: "append() expects a list first argument")
        list.append(try evaluate(args[1]))
        return .null
    }

    // builtinPrepend prepends a ProgramValue to a list.
    // If the new element is a string PValue the list becomes the owner of that string.
    func builtinPrepend(_ args: [ProgramNode]) throws -> ProgramValue {
        var list = try evaluateList(args[0], errMessage: "append() expects a list first argument")
        list.prepend(try evaluate(args[1]))
        return .null
    }

    // builtinRemoveFirst removes the first ProgramValue from a list.
    func builtinRemoveFirst(_ args: [ProgramNode]) throws -> ProgramValue {
        var list = try evaluateList(args[0], errMessage: "removeFirst() expects a list argument")
        guard let first =  list.removeFirst() else { return .null }
        return first
    }

    // UTILITIES
    func evaluateList(_ node: ProgramNode, errMessage: String) throws -> List<ProgramValue> {
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
