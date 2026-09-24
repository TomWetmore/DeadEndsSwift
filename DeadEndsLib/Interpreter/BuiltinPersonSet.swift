//
//  BuiltinPersonSet.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 17 April 2026.
//  Last changed on 23 September 2026.
//

import Foundation

/// PersonSet built-ins.

extension Program {

    /// Built-in that creates and returns a PersonSet.
    /// personset() -> personset

    func bltinPersonSet(_ args: [ParsedExpr]) throws -> ProgramValue {

        return .personset(PersonSet())
    }

    /// Built-in that adds a new PersonSetElement to a PersonSet. If there is no associated
    /// value the third argument can be omitted.
    /// addtoset(personset, person[, any]) -> null

    func bltinAddToSet(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let personSet = try await evalPersonSet(args[0],
                                    errMsg: "addtoset: 1st arg must be a personset")
        let person = try await evalPerson(args[1],
                                    errMsg: "addtoset: 2nd arg must be a person")
        var any = ProgramValue.null
        if args.count == 3 {
            any = try await evaluate(args[2])
        }
        personSet.append(person, value: any)
        return .null
    }

    /// Built-in that deletes an element from a PersonSet.
    /// TODO: Current definitions allows the same person to be in the set multiple times!!!!!
    /// What are the ramifications of this???
    /// deletefromset(personset, person) -> null

    func bltinDeleteFromSet(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let set = try await evalPersonSet(args[0],
                                          errMsg: "deletefromset: 1st arg must be a personset")
        let person = try await evalPerson(args[1],
                                          errMsg: "deletefromset: 2nd arg must be a person")
        set.remove(key: person.key)
        return .null
    }

    /// Built-in that sorts a PersonSet by name.
    /// namesort(personset) -> null

    func bltinNameSort(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let set = try await evalPersonSet(args[0],
                                    errMsg: "namesort: arg must be a personset")
        set.nameSort()
        return .null
    }

    /// Builtin that sorts a person set by key.
    /// keysort(personset) -> null

    func bltinKeySort(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let set = try await evalPersonSet(args[0],
                                    errMsg: "keysort: arg must be a personset")
        set.keySort()
        return .null
    }

    /// Built-in that uniques a personset.
    /// uniqueset(personset) -> null

    func builtinUniqueset(_ args: [ParsedExpr]) throws -> ProgramValue {

        
        throw RuntimeError("uniqueset: not implemented", line: args[0].line)
    }
}

/// General set operations on person sets.

extension Program {

    /// Built-in that returns the union of two person sets.
    /// union(personset, personset) -> personset

    func bltinUnion(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let set1Value = try await evaluate(args[0])
        guard case let .personset(set1) = set1Value else {
            throw RuntimeError("union: 1st arg must be a personset", line: args[0].line)
        }
        let set2Value = try await evaluate(args[1])
        guard case let .personset(set2) = set2Value else {
            throw RuntimeError("union: 2nd arg must be a personset", line: args[0].line)
        }
        return .personset(set1.union(set2))
    }

    /// Built-in that returns the intersection of two person sets.
    /// intersect(personset, personset) -> personset

    func bltinIntersect(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let set1Value = try await evaluate(args[0])
        guard case let .personset(set1) = set1Value else {
            throw RuntimeError("intersect: 1st arg must be a personset", line: args[0].line)
        }
        let set2Value = try await evaluate(args[1])
        guard case let .personset(set2) = set2Value else {
            throw RuntimeError("intersect: 2nd arg must be a personset", line: args[1].line)
        }
        return .personset(set1.intersection(set2))
    }

    /// Built-in that returns the difference of two person sets.
    /// difference(personset, personset) -> personset

    func bltinDifference(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let set1Value = try await evaluate(args[0])
        guard case let .personset(set1) = set1Value else {
            throw RuntimeError("difference: 1st arg must be a personset", line: args[0].line)
        }
        let set2Value = try await evaluate(args[1])
        guard case let .personset(set2) = set2Value else {
            throw RuntimeError("difference: 2nd arg must be a personset", line: args[1].line)
        }
        return .personset(set1.difference(set2))
    }
}

/// Genealogical operations on person sets.

extension Program {

    /// Built-in that returns the parent person set of a person set.
    /// parentset(personset) -> personset

    func bltinParentSet(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let setValue = try await evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("parentset: arg must be a personset", line: args[0].line)
        }
        return .personset(set.parents(in: recordIndex))
    }

    /// Built-in that returns the children person set of a person set.
    /// childset(personset) -> personset

    func bltinChildSet(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let setValue = try await evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("childset: arg must be a personset", line: args[0].line)
        }
        return .personset(set.children(in: recordIndex))
    }

    /// Built-in that return the sibling person set of a person set.
    /// siblingset(personset) -> personset

    func bltinSiblingSet(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let setValue = try await evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("siblingset: arg must be a personset", line:args[0].line)
        }
        return .personset(set.siblings(in: recordIndex))
    }

    /// Built-in that returns the spouse person set of a person set.
    /// spouseset(personset) -> personset

    func bltinSpouseSet(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let setValue = try await evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("spouseset: arg must be a personset", line: args[0].line)
        }
        return .personset(set.spouses(in: recordIndex))
    }

    /// Built-in that returns the ancestor person set of a person set.
    /// ancestorset(personset) -> personset

    func bltinAncestorSet(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let setValue = try await evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("ancestorset: arg must be a personset", line: args[0].line)
        }
        return .personset(set.ancestors(in: recordIndex))
    }

    /// Built-in that returns the descendant person set of a person set.
    /// descend[a|e]ntset(personset) -> personset

    func bltinDescendentSet(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let setValue = try await evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("descendentset: arg must be a personset", line: args[0].line)
        }
        return .personset(set.descendants(in: recordIndex))
    }

    /// Built-in that generates Gedcom text from a PersonSet.
    /// gengedcom(personset) -> string

    func bltinGenGedcom(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let setValue = try await evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("gengedcom: arg must be a personset", line: args[0].line)
        }
        let persons = set.map { $0.person }
        let index = personsToRecordIndex(persons: persons, in: recordIndex)

        for record in index.values {
            let recordText = record.root.gedcomText(level: 0, indent: false)
            output.writeLine(recordText)
        }
        return .null
    }
}
