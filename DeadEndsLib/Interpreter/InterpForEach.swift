//
//  InterpForEach.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 5/1/26.
//  Last changed on 20 May 2026.
//

import Foundation

extension Program {

    /// Interpret a foreach statement.
    func interpForEach(_ stmt: ParsedForEachStmt) async throws -> InterpResult {

        let line = stmt.listExpr.line

        switch try await evaluate(stmt.listExpr) {
        case .list(let list):
            for (i, value) in list.enumerated() {
                let result = try await interpBody(stmt, element: value, payload: .null, index: i + 1)
                if let final = handleLoopResult(result) {
                    return final
                }
            }
        case .personset(let set):
            for (i, element) in set.enumerated() {
                let result = try await interpBody(stmt, element: .person(element.person),
                                        payload: element.payload ?? .null, index: i + 1)
                if let final = handleLoopResult(result) {
                    return final
                }
            }
        case .allPersons:
            for (i, element) in database.persons.enumerated() {
                let result = try await interpBody(stmt, element: .person(Person(element)),
                                        payload: .null, index: i + 1)
                if let final = handleLoopResult(result) {
                    return final
                }
            }
        case .allFamilies:
            for (i, element) in database.families.enumerated() {
                let result = try await interpBody(stmt, element: .family(Family(element)),
                                            payload: .null, index: i + 1)
                if let final = handleLoopResult(result) {
                    return final
                }
            }
        case .traverse(let node):
            let nodes = node.preorderNodes()
            for (i, node) in nodes.enumerated() {
                let result = try await interpBody(stmt, element: .gnode(node),
                                        payload: .null, index: i + 1)
                if let final = handleLoopResult(result) {
                    return final
                }
            }
        case .null:
            return .okay
        default:
            throw RuntimeError("foreach: 1st arg must be a sequence", line: line)
        }
        return .okay
    }

    /// Interpret the body of an iteration.
    private func interpBody(_ stmt: ParsedForEachStmt, element: ProgramValue,
                            payload: ProgramValue, index: Int) async throws -> InterpResult {

        assignToSymbol(stmt.elementVar, value: element)
        if let valueVar = stmt.valueVar {
            assignToSymbol(valueVar, value: payload)
        }
        assignToSymbol(stmt.indexVar, value: .integer(index))

        let result = try await interpStmtList(stmt.body)
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

extension GedcomNode {

    func preorderNodes() -> [GedcomNode] {
        var result: [GedcomNode] = []

        func visit(_ node: GedcomNode) {
            result.append(node)

            var child = node.kid
            while let current = child {
                visit(current)
                child = current.sib
            }
        }
        visit(self)
        return result
    }
}
