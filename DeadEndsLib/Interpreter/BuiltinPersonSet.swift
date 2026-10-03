//
//  BuiltinPersonSet.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 17 April 2026.
//  Last changed on 3 October 2026.
//

import Foundation

/// PersonSet built-ins.

extension Program {

    /// Built-in that creates and returns a PersonSet.
    /// personset() -> personset
    ///
    func bltinPersonSet(_ args: [ParsedExpr]) throws -> ProgramValue {

        return .personset(PersonSet())
    }

    /// Add a Person or Persons in a PersonSet or a List to a PersonSet.
    /// An associated value may be supplied when adding a single person.
    /// addtoset(personset, person[, any]) -> null
    /// addtoset(personset, list<person>) -> null
    /// addtoset(personset, personset) -> null
    ///
    func bltinAddToSet(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let personSet = try await evalPersonSet(args[0],
            errMsg: "addtoset: 1st arg must be a personset")

        switch try await evaluate(args[1]) {

        case .person(let person):
            let any = args.count == 3 ? try await evaluate(args[2]) : .null
            personSet.insert(person, value: any)

        case .list(let list):
            guard args.count == 2 else {
                throw RuntimeError(
                    "addtoset: associated value not allowed when adding list"
                )
            }
            for value in list.elements {
                guard case .person(let person) = value else {
                    throw RuntimeError(
                        "addtoset: list must contain only persons"
                    )
                }
                personSet.insert(person)
            }

        case .personset(let other):
            guard args.count == 2 else {
                throw RuntimeError(
                    "addtoset: associated value not allowed when adding personset"
                )
            }
            personSet.formUnion(other)

        default:
            throw RuntimeError("addtoset: 2nd arg must be a person or personset")
        }
        return .null
    }

    /// Delete an element from a PersonSet.
    /// deletefromset(personset, person) -> null
    ///
    func bltinDeleteFromSet(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let set = try await evalPersonSet(args[0],
                                          errMsg: "deletefromset: 1st arg must be a personset")
        let person = try await evalPerson(args[1],
                                          errMsg: "deletefromset: 2nd arg must be a person")
        set.remove(key: person.key)
        return .null
    }

    /// Sort a PersonSet by name.
    /// namesort(personset) -> null
    ///
    func bltinNameSort(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let set = try await evalPersonSet(args[0],
                                    errMsg: "namesort: arg must be a personset")
        set.nameSort()
        return .null
    }

    /// Sort a PersonSet by key.
    /// keysort(personset) -> null
    ///
    func bltinKeySort(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let set = try await evalPersonSet(args[0],
                                    errMsg: "keysort: arg must be a personset")
        set.keySort()
        return .null
    }
}

/// General set operations on person sets.

extension Program {

    /// Return the union of two PersonSets.
    /// union(personset, personset) -> personset
    ///
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

    /// Return the intersection of two PersonSets.
    /// intersect(personset, personset) -> personset
    ///
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

    /// Return the set difference of two PersonSets.
    /// difference(personset, personset) -> personset
    ///
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

    /// Built-in that generates Gedcom text from a PersonSet.
    /// gengedcom(personset) -> string
    ///
    func bltinGenGedcom(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let setValue = try await evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("gengedcom: arg must be a personset", line: args[0].line)
        }
        let persons = set.map { $0.person }
        let index = personsToRecordIndex(persons, in: recordIndex)

        for record in index.values {
            let recordText = record.root.gedcomText(indent: "")
            output.writeLine(recordText)
        }
        return .null
    }
}
