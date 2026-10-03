//
//  BuiltinList.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 11 April 2026.
//  Last changed on 3 October 2026.
//

import Foundation

/// Builtins are methods on Programs.
extension Program {

    /// Create and return an empty list.
    /// list() -> list
    ///
    func bltinList(_ args: [ParsedExpr]) throws -> ProgramValue {
        return .emptyList
    }

    /// Return whether a list, table, personset or string is empty.
    /// empty(list|table|personset|string) -> bool
    func bltinEmpty(_ args: [ParsedExpr]) async throws -> ProgramValue {

        switch try await evaluate(args[0]) {

        case .list(let list):
            return list.count == 0 ? .trueProgramValue : .falseProgramValue

        case .table(let table):
            return table.count == 0 ? .trueProgramValue : .falseProgramValue

        case .personset(let set):
            return set.count == 0 ? .trueProgramValue : .falseProgramValue

        case .string(let string):
            return string.isEmpty ? .trueProgramValue : .falseProgramValue

        default:
            throw RuntimeError(
                "empty: arg must be a list, table, personset, or string",
                line: args[0].line
            )
        }
    }

    /// Clear the contents of a list, table, or personset.
    /// clear(list|table|personset) -> (list|table|personset)
    ///
    func bltinClear(_ args: [ParsedExpr]) async throws -> ProgramValue {

        switch try await evaluate(args[0]) {

        case .list(let list):
            list.clear()
            return .list(list)

        case .table(let table):
            table.clear()
            return .table(table)

        case .personset(let personset):
            personset.clear()
            return .personset(personset)

        default:
            throw RuntimeError("clear: arg must be a list, table, or personset",
                               line: args[0].line)
        }
    }

    /// Return the length of a list, table, personset or string.
    /// length(list|table|personset|string) -> int
    ///
    func bltinLength(_ args: [ParsedExpr]) async throws -> ProgramValue {

        switch try await evaluate(args[0]) {

        case .list(let list):
            return .integer(list.count)

        case .table(let table):
            return .integer(table.count)

        case .personset(let set):

            return .integer(set.count)
        case .string(let string):
            return .integer(string.count)
            
        default:
            throw RuntimeError("length: arg must be a list, table, personset, or string",
                               line: args[0].line)
        }
    }

    /// Append a value to a list.
    func bltinAppend(_ args: [ParsedExpr]) async throws -> ProgramValue {

        guard let list = try await evaluateListOpt(args[0],
                                                   errMsg: "append: 1st arg must be a list")
        else { return .null }
        await list.append(try evaluate(args[1]))
        return .list(list)
    }

    /// Prepend a value to a list.
    func bltinPrepend(_ args: [ParsedExpr]) async throws -> ProgramValue {

        guard let list = try await evaluateListOpt(args[0],
                                                   errMsg: "prepend: 1st arg must be a list")
        else { return .null }
        await list.prepend(try evaluate(args[1]))
        return .list(list)
    }

    /// Remove the first value from a list.
    func bltinRemoveFirst(_ args: [ParsedExpr]) async throws -> ProgramValue {

        guard let list = try await evaluateListOpt(args[0],
                                                   errMsg: "removefirst: 1st arg must be a list")
        else { return .null }
        guard let first = list.removeFirst() else { return .null }
        return first
    }

    /// Remove the last value from a list.
    func bltinRemoveLast(_ args: [ParsedExpr]) async throws -> ProgramValue {

        guard let list = try await evaluateListOpt(args[0],
                                                   errMsg: "removelast: 1st arg must be a list")
        else { return .null }
        guard let last = list.removeLast() else { return .null }
        return last
    }

    /// Evaluate an expression and be sure it is a list.
    func evaluateList(_ expr: ParsedExpr, errMsg: String) async throws -> ListValue {

        guard case let .list(list) = try await evaluate(expr) else {
            throw RuntimeError(errMsg, line: expr.line)
        }
        return list
    }

    /// Evaluate an expression and be sure it is a list or nil.
    func evaluateListOpt(_ expr: ParsedExpr, errMsg: String) async throws -> ListValue? {

        switch try await evaluate(expr) {
        case .list(let list):
            return list
        case .null:
            return nil
        default:
            throw RuntimeError(errMsg, line: expr.line)
        }
    }
}

/// Builtins that return lists of persons or families.
extension Program {

    /// Return the number of children or a Person or Family.
    /// nchildren(person|family) -> integer
    /// nchildren(null) -> null
    ///
    func bltinNChildren(_ args: [ParsedExpr]) async throws -> ProgramValue {

        switch try await bltinChildren(args) {

        case .null:
            return .null

        case .list(let l):
            return .integer(l.count)

        default:
            throw RuntimeError("nchildren: arg must be a person or family",
                               line: args[0].line)
        }
    }

    /// Return the number of spouses of a Person or Family.
    /// nspouses(person|family) -> integer
    /// nspouses(null) -> null
    ///
    func bltinNSpouses(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let spouses = try await bltinSpouses(args)
        switch spouses {

        case .null:
            return .null

        case .list(let l):
            return .integer(l.count);
            
        default:
            throw RuntimeError("nchildren: arg must be a person or family",
                               line: args[0].line)
        }
    }

    /// Return the list of Families a Person is in as a spouse.
    /// families(person) -> list<family>
    /// families(null) -> empty list
    ///
    func bltinFamilyList(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let line = args[0].line
        var families = [Family]()

        switch try await evaluate(args[0]) {

        case .person(let person):
            families = person.spouseFamilies(in: recordIndex)

        case .null:
            return .emptyList
            
        default:
            throw RuntimeError("families: arg must be a person", line: line)
        }
        let result = ListValue(families.map { ProgramValue.family($0)})
        return .list(result)
    }

    /// TO: FIND  BETTER PLACE
    /// Return...
    func bltinNodes(_ args: [ParsedExpr]) async throws -> ProgramValue {
        let value = try await evaluate(args[0])
        guard case .gnode(let gedcomNode) = value else {
            throw RuntimeError("nodes: arg must be a gnode", line: args[0].line)
        }
        return .traverse(gedcomNode)
    }

    /// bltinSubscript returns the ith (relative one) element of a sequence.
    /// subscript(List|PersonSet|String, Integer) -> Any
    func bltinSubscript(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let sequenceValue = try await evaluate(args[0])
        let index = try await evalInteger(args[1],
                                          errMsg: "subscript: 2nd arg must be an integer")
        let internalIndex = index - 1

        switch sequenceValue { // Get the list or person set from the first arg.
        case .list(let list):
            guard list.elements.indices.contains(internalIndex) else {
                throw RuntimeError("subscript: index \(index) is out of range",
                                   line: args[1].line)
            }
            return list[internalIndex]
        case .personset(let personset):
            guard personset.elements.indices.contains(internalIndex) else {
                throw RuntimeError("subscript: index \(index) is out of range",
                                   line: args[1].line)
            }
            return .person(personset.elements[internalIndex].person)
        case .string(let string):
            guard index >= 1 && index <= string.count else {
                throw RuntimeError("subscript: index \(index) is out of range",
                                   line: args[1].line)
            }
            let stringIndex = string.index(string.startIndex, offsetBy: internalIndex)
            return .string(String(string[stringIndex]))
        default:
            throw RuntimeError("subscript: 1st arg must be a list or personset",
                               line: args[0].line)
        }
    }
}

/// Tuple support.
extension Program {

    /// Built-in that creates a pair ProgramValue
    func bltinPair(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let first = try await evaluate(args[0])
        let second = try await evaluate(args[1])
        return .pair(Pair(first, second))
    }

    /// Built-in that returns the first component of a pair.
    func bltinFirst(_ args: [ParsedExpr]) async throws -> ProgramValue {
        guard case let .pair(pair) = try await evaluate(args[0]) else {
            throw RuntimeError("first: arg must be a pair", line: args[0].line)
        }
        return pair.first
    }

    /// Built-in that returns the second component of a pair.
    func bltinSecond(_ args: [ParsedExpr]) async throws -> ProgramValue {
        guard case let .pair(pair) = try await evaluate(args[0]) else {
            throw RuntimeError("second: arg must be pair", line: args[0].line)
        }
        return pair.second
    }
}

extension Program {

    /// Return a shallow copy of a list.
    /// copy(list|null) -> list
    ///
    func bltinCopy(_ args: [ParsedExpr]) async throws -> ProgramValue {
        guard let list = try await evaluateListOpt(args[0],
                                        errMsg: "copy: arg must be a list") else {
            return .emptyList
        }
        return .list(list.copy())
    }
}

/// Structure that holds the programming language's list values. These are the
/// enumerated .list elements that have an array of program values for their
/// associated types.
/// 
public class ListValue {

    /// A list program value is an array of program values.
    var elements: [ProgramValue] = []

    /// The number of program values in this list.
    var count: Int { elements.count }

    /// Create a list from an array of program values.
    public init(_ values: [ProgramValue] = []) {
        self.elements = values
    }

    /// Push a program value onto a list (treated as a stack).
    func push(_ element: ProgramValue) {
        elements.insert(element, at: 0)
    }

    /// Pop a program value from a list (treated as a stack).
    func pop() -> ProgramValue? {
        guard !elements.isEmpty else { return nil }
        return elements.removeFirst()
    }

    /// Enqueue a program value on a list (treated as a queue).
    func enqueue(_ element: ProgramValue) {
        elements.append(element)
    }

    /// Dequeue a program value from a list (treated as a queue).
    func dequeue() -> ProgramValue? {
        guard !elements.isEmpty else { return nil }
        return elements.removeFirst()
    }

    /// Append a program value to a list.
    func append(_ element: ProgramValue) {
        elements.append(element)
    }

    /// Prepend a program value to a list.
    func prepend(_ element: ProgramValue) {
        elements.insert(element, at: 0)
    }

    /// Remove the first program value from a list
    func removeFirst() -> ProgramValue? {
        guard !elements.isEmpty else { return nil }
        return self.elements.removeFirst()
    }

    /// Remove the last program value from a list.
    func removeLast() -> ProgramValue? {
        guard !elements.isEmpty else { return nil }
        return self.elements.removeLast()
    }

    /// Remove all program values from a list.
    func clear() {
        elements.removeAll(keepingCapacity: false)
    }

    /// Returns a shallow copy of a list.
    public func copy() -> ListValue {
        ListValue(elements)
    }

    /// Simple subscript operation for a list.
    subscript(index: Int) -> ProgramValue {
        get { elements[index] }
        set { elements[index] = newValue }
    }

    /// Sort the program values in a list using a comparison function.
    func sort(by areInIncreasingOrder: (ProgramValue, ProgramValue) -> Bool) {
        elements.sort(by: areInIncreasingOrder)
    }
}

/// Needed to make List mappable.
extension ListValue: Sequence {
    
    public func makeIterator() -> IndexingIterator<[ProgramValue]> {
        elements.makeIterator()
    }
}
