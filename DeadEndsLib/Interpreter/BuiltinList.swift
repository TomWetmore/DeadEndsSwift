//
//  BuiltinList.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 11 April 2026.
//  Last changed on 27 May 2026.
//

import Foundation

/// Builtins are methods on Programs.
extension Program {

    /// Return an empty list.
    func bltinList(_ args: [ParsedExpr]) throws -> ProgramValue {
        return .list(List())
    }

    /// Return whether a list, table, person set or string is empty.
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

    /// Clear the contents of a list, table, or person set.
    func bltinClear(_ args: [ParsedExpr]) throws -> ProgramValue {

        guard case let .identifier(name) = args[0].kind else {
            throw RuntimeError(
                "clear: arg must be a list, table, or personset variable",
                line: args[0].line
            )
        }
        guard let value = lookupSymbol(name) else {
            throw RuntimeError("undefined variable: \(name)", line: args[0].line)
        }
        switch value {
        case .list(let list):
            list.clear()
            assignToSymbol(name, value: .list(list))
        case .table(let table):
            table.clear()
            assignToSymbol(name, value: .table(table))
        case .personset(let personset):
            personset.clear()
            assignToSymbol(name, value: .personset(personset))
        default:
            throw RuntimeError("clear: arg must be a list, table, or personset variable",
                line: args[0].line)
        }
        return .null
    }

    /// Return the length of a list, table, person set or string.
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

    /// Append a value to a list. This method requires the first argument to be a
    /// variable with a list value in the symbol table.
    func bltinAppend(_ args: [ParsedExpr]) async throws -> ProgramValue {

        guard let list = try await evaluateListOpt(args[0], errMsg: "append: 1st arg must be a list") else {
            return .null
        }
        await list.append(try evaluate(args[1]))
        return .null
    }

    /// Prepend a value to a list.
    func bltinPrepend(_ args: [ParsedExpr]) async throws -> ProgramValue {
        let (name, list) =
            try requireListVariable(args[0], errMsg: "prepend: 1st arg must be a list var")
        await list.prepend(try evaluate(args[1]))
        assignToSymbol(name, value: .list(list))
        return .null
    }

    /// Remove the first value from a list.
    func bltinRemoveFirst(_ args: [ParsedExpr]) throws -> ProgramValue {
        let (name, list) =
            try requireListVariable(args[0], errMsg: "removefirst: 1st arg must be a list var")
        guard let first = list.removeFirst() else { return .null }
        assignToSymbol(name, value: .list(list))
        return first
    }

    /// Evaluate an expression and be sure it is a list.
    func evaluateList(_ expr: ParsedExpr, errMsg: String) async throws -> List {
        guard case let .list(list) = try await evaluate(expr) else {
            throw RuntimeError(errMsg, line: expr.line)
        }
        return list
    }

    /// Evaluate an expression and be sure it is a list or nil.
    func evaluateListOpt(_ expr: ParsedExpr, errMsg: String) async throws -> List? {
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

    /// Return the children of a person or family as a List.
    func bltinChildren(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let line = args[0].line
        var children = [Person]()

        switch try await evaluate(args[0]) {
        case .person(let person):
            children = person.children(in: recordIndex)
        case .family(let family):
            children = family.children(in: recordIndex)
        case .null:
            return .null
        default:
            throw RuntimeError("children: arg must be a person or family", line: line)
        }
        return .list(List(children.map { ProgramValue.person($0) }))
    }

    /// Return the list of husbands of a person or family.
    func bltinHusbands(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let line = args[0].line
        var husbands = [Person]()

        switch try await evaluate(args[0]) {
        case .person(let person):
            husbands = person.husbands(in: recordIndex)
        case .family(let family):
            husbands = family.husbands(in: recordIndex)
        case .null:
            return .null
        default:
            throw RuntimeError("husbands: arg must be a person or family", line: line)
        }
        return .list(List(husbands.map { ProgramValue.person($0)}))
    }

    /// Return the list of wives of a person or family.
    func bltinWives(_ args: [ParsedExpr]) async throws -> ProgramValue {
        let line = args[0].line
        var wives = [Person]()

        switch try await evaluate(args[0]) {
        case .person(let person):
            wives = person.wives(in: recordIndex)
        case .family(let family):
            wives = family.wives(in: recordIndex)
        case .null:
            return .null
        default:
            throw RuntimeError("wives: arg must be a person or family", line: line)
        }
        return .list(List(wives.map { ProgramValue.person($0)}))
    }

    /// Return the list of siblings of a person.
    func bltinSiblings(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let line = args[0].line
        var siblings = [Person]()

        switch try await evaluate(args[0]) {
        case .person(let person):
            siblings = person.siblings(in: recordIndex)
        case .null:
            return .null
        default:
            throw RuntimeError("siblings: arg must be a person", line: line)
        }
        return .list(List(siblings.map { ProgramValue.person($0)}))
    }

    /// Return the list of spouses of a person or family.
    func bltinSpouses(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let line = args[0].line
        var spouses = [Person]()

        switch try await evaluate(args[0]) {
        case .person(let person):
            spouses = person.spouses(in: recordIndex)
        case .family(let family):
            spouses = family.spouses(in: recordIndex)
        case .null:
            return .null
        default:
            throw RuntimeError("spouses: arg must be a person or family",
                                                line: line)
        }
        return .list(List(spouses.map { ProgramValue.person($0) }))
    }

    /// Return the list of parents of a person or family (the spouses).
    func bltinParents(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let line = args[0].line
        var parents = [Person]()

        switch try await evaluate(args[0]) {
        case .person(let person):
            parents = person.parents(in: recordIndex)
        case .family(let family):
            parents = family.spouses(in: recordIndex) // Define parents of a family and the spouses.
        case .null:
            return .null
        default:
            throw RuntimeError("parents: arg must be a person", line: line)
        }
        return .list(List(parents.map { ProgramValue.person($0) }))
    }

    /// Return the list of families a person is in as a spouse.
    /// families(person) -> .list(Family)
    func bltinFamilyList(_ args: [ParsedExpr]) async throws -> ProgramValue {
        let line = args[0].line
        var families = [Family]()

        switch try await evaluate(args[0]) {
        case .person(let person):
            families = person.spouseFamilies(in: recordIndex)
        case .null:
            return .null
        default:
            throw RuntimeError("spouses: arg must be a person", line: line)
        }
        let result = List(families.map { ProgramValue.family($0)})
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
    /// subscript(sequence, i) -> value
    /// TODO: Calling the list a sequence, anticipating making this a generic.
    func bltinSubscript(_ args: [ParsedExpr]) async throws -> ProgramValue {

        guard let sequence = try await evaluateListOpt(args[0], errMsg: "subscript: 1st arg must be a sequence") else {
            return .null
        }
        let index = try await evaluateInteger(args[1], errMsg: "subscript: 2nd arg must be an integer")
        let internalIndex = index - 1
        guard internalIndex >= 0 && internalIndex < sequence.count else {
            throw RuntimeError("subscript: index \(index) is out of range", line: args[1].line)
        }
        return sequence[internalIndex]
    }
}

/// Structure that holds the programming language's List values.
public class List {

    private var values: [ProgramValue] = []

    var count: Int { values.count }

    public init(_ values: [ProgramValue] = []) {
        self.values = values
    }

    func push(_ element: ProgramValue) {
        values.insert(element, at: 0)
    }

    func pop() -> ProgramValue? {
        guard !values.isEmpty else { return nil }
        return values.removeFirst()
    }

    func enqueue(_ element: ProgramValue) {
        values.append(element)
    }

    func dequeue() -> ProgramValue? {
        guard !values.isEmpty else { return nil }
        return values.removeFirst()
    }

    func append(_ element: ProgramValue) {
        values.append(element)
    }

    func prepend(_ element: ProgramValue) {
        values.insert(element, at: 0)
    }

    func removeFirst() -> ProgramValue? {
        guard !values.isEmpty else { return nil }
        return self.values.removeFirst()
    }

    func clear() {
        values.removeAll(keepingCapacity: false)
    }

    subscript(index: Int) -> ProgramValue {
        get { values[index] }
        set { values[index] = newValue }
    }

    func sort(by areInIncreasingOrder: (ProgramValue, ProgramValue) -> Bool) {
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
    func requireListVariable(_ expr: ParsedExpr, errMsg: String )
        throws -> (name: String, list: List) {

        guard case let .identifier(name) = expr.kind else {
            throw RuntimeError(errMsg, line: expr.line)
        }
        guard let value = lookupSymbol(name) else {
            throw RuntimeError("undefined variable: \(name)", line: expr.line)
        }
        guard case let .list(list) = value else {
            throw RuntimeError(errMsg, line: expr.line)
        }

        return (name, list)
    }
}
