//
//  BuiltinInterface.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 14 May 2026.
//  Last changed on 14 May 2026.
//

import Foundation

extension Program {

    /// 
    func bltinChoosePerson(_ args: [ParsedExpr]) throws -> ProgramValue {

        // 1. Evaluate the argument to get a string.
        // 2. Treat that string as name pattern and get all the persons who match.
        // 3. First for testing just return the list and let the calling program show it.
        // 4. Later, interaction with choose one of the persons and a .person(person) will be returned.

        guard let pattern = try evaluateStringOpt(args[0],
                                    errMsg: "chooseperson: arg must be a name pattern") else {
            return .null
        }
        return .list(List(database.persons(withName: pattern).map { ProgramValue.person($0) }))
    }
}



/// Evaluate an expression for an optional person; throw error if not a person or null.
extension Program {
    func evaluateStringOpt(_ expr: ParsedExpr, errMsg: String) throws -> String? {

        switch try evaluate(expr) {
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

    func evaluateString(_ expr: ParsedExpr, errMsg: String) throws -> String {
        switch try evaluate(expr) {
        case .string(let string):
            return string
        default: throw RuntimeError(errMsg, line: expr.line)
        }
    }
}
