//
//  InterpSpecialForms.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 5/1/26.
//  Last changed on 8 May 2026.
//

import Foundation

extension Program {

    /// Interpret a foreach statement.
    func interpForEach(_ stmt: ParsedForEachStmt) throws -> InterpResult {

        let line = stmt.listExpr.line

        switch try evaluate(stmt.listExpr) {
        case .list(let list):
            for (i, value) in list.enumerated() {
                let result = try runForEachBody(stmt, element: value, payload: .null, index: i + 1)
                if let final = handleLoopResult(result) {
                    return final
                }
            }
        case .personset(let set):
            for (i, element) in set.enumerated() {
                let result = try runForEachBody(stmt, element: .person(element.person),
                                                payload: element.payload ?? .null, index: i + 1)
                if let final = handleLoopResult(result) {
                    return final
                }
            }
//        case .person(let person):
//        case .family(let family):
//        case .node(let node):
        case .null:
            return .okay
        default:
            throw RuntimeError.typeMismatch("foreach: first arg must be a list or person set", line: line)
        }
        return .okay
    }

    /// Interpret the body one time.
    private func runForEachBody(_ stmt: ParsedForEachStmt, element: ProgramValue, payload: ProgramValue,
                                index: Int) throws -> InterpResult {

        assignToSymbol(stmt.elementVar, value: element)
        if let valueVar = stmt.valueVar {
            assignToSymbol(valueVar, value: payload)
        }
        assignToSymbol(stmt.indexVar, value: .integer(index))

        let result = try interpStmtList(stmt.body)
        return result
    }

    private func handleLoopResult(_ result: InterpResult) -> InterpResult? {
        switch result {
        case .okay, .continuing:
            return nil          // keep looping
        case .breaking:
            return .okay        // consume the break
        case .returning:
            return result       // propagate return upward
        case .error:
            return result       // propagate error upward
        }
    }
}
