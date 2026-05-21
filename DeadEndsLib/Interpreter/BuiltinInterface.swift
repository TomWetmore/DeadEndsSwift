//
//  BuiltinInterface.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 14 May 2026.
//  Last changed on 21 May 2026.
//

import Foundation

extension Program {

    /// Get the user to identify a single person.
    /// getperson(message: string) -> person?
    func bltinGetPerson(_ args: [ParsedExpr]) async throws -> ProgramValue {
        let prompt = try await evaluateString(args[0],
                            errMsg: "getperson: arg must be a prompt message")
        let person = await userInterface.getPerson(prompt: prompt)
        if let person {
            return .person(person)
        }
        return .null
    }

    /// chooseperson(msg: String, pattern: String) -> Person?
//    func bltinChoosePerson(_ args: [ParsedExpr]) async throws -> ProgramValue {
//
//        let prompt = try evaluateString(args[0],
//                                    errMsg:"chooseperson: 1st arg must be a prompt message")
//        let pattern = try evaluateString(args[1],
//                                    errMsg: "chooseperson: 2nd arg must be a name pattern")
//        let candidates = database.persons(withName: pattern)
//
//        await output.flush()
//
//        guard let person = await userInterface.choosePerson(prompt: prompt, candidates: candidates)
//        else { return .null }
//        return .person(person)
//    }
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
