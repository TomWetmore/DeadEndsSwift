//
//  BuiltinInterface.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 14 May 2026.
//  Last changed on 23 July 2026.
//

import Foundation

extension Program {

    /// Get the user to identify a single person.
    /// getperson(message: string) -> person?
    /// This is the original version used by the SwiftUI based interface.
    func bltinGetPerson(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let prompt = try await evaluateString(args[0], errMsg: "getperson: arg must be a prompt")
        await output.flush()
        let person = await userInterface.getPerson(prompt: prompt)
        if let person {
            return .person(person)
        }
        return .null
    }

    /// This is the new version that uses the new version of getPerson
    func nbltinGetPerson(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let prompt = try await evaluateString(args[0], errMsg: "getperson: arg must be a prompt")
        await output.flush()
        let person = await userInterface.ngetPerson(prompt: prompt, database: database)
        if let person {
            return .person(person)
        }
        return .null
    }

//    func nbuiltinGetPerson(_ args: [ParsedExpr]) async throws -> ProgramValue {
//
//        let prompt = try await evaluateString(args[0], errMsg: "getperson: arg must be a prompt")
//        await output.flush()
//        guard let name = await userInterface.getString(prompt: prompt) else {
//            return .null
//        }
//
//        // Get the persons who match the name, sorted by name.
//        let persons = database.persons(withName: name)
//
//        guard !persons.isEmpty else {
//            return .null
//        }
//
//        guard let person = await userInterface.getPerson(
//            prompt: "Select a person",
//            persons: persons
//        ) else {
//            return .null
//        }
//
//        return .person(person)
//    }

    /// Get the user to enter an integer.
    /// getinteger(messagte: String) -> Int?
    func bltinGetInteger(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let prompt = try await evaluateString(args[0], errMsg: "getinteger: arg must be a prompt")
        await output.flush()
        let result = await userInterface.getInteger(prompt: prompt)
        if let result {
            return .integer(result)
        }
        return .null
    }

    /// Get the user to enter a string.
    /// getstring(prompt) -> string?
    func bltinGetString(_ args: [ParsedExpr]) async throws -> ProgramValue {
        let prompt = try await evaluateString(args[0], errMsg: "getstring: arg must be a prompt")
        await output.flush()
        let result = await userInterface.getString(prompt: prompt)
        if let result {
            return .string(result)
        }
        return .null
    }
}

/// Evaluate an expression for an optional person; throw error if not a person or null.
/// TODO: MOVE TO THE RIGHT PLACE.
extension Program {
    func evaluateStringOpt(_ expr: ParsedExpr, errMsg: String) async throws -> String? {

        switch try await evaluate(expr) {
        case .string(let string):
            return string
        case .null:
            return nil
        default:
            throw RuntimeError(errMsg, line: expr.line)
        }
    }
}

/// Evaluate an expression that must be a string
/// TODO: MOVE TO THE RIGHT PLACE
extension Program {

    /// Evaluate an expression to a non-optional string.
    func evaluateString(_ expr: ParsedExpr, errMsg: String) async throws -> String {
        switch try await evaluate(expr) {
        case .string(let string):
            return string
        default: throw RuntimeError(errMsg, line: expr.line)
        }
    }
}
