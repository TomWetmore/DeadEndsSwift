//
//  InterpForEach.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 1 May 2026.
//  Last changed on 8 October 2026.
//

import Foundation

extension Program {

    /// Interpret a foreach statement. Foreach statements handle lists, person sets, tables,
    /// strings, persons, families, and sub-nodes.
    /// foreach(List|PersonSet|Table|String|Persons|Families|Nodes, String, String?, String)
    ///
    func interpForEach(_ stmt: ParsedForEachStmt) async throws -> InterpResult {

        // Handle cases where the foreach identifiers hide identifiers already in use.
        let savedElement = lookupLocal(stmt.elementVar)
        let savedValue = stmt.valueVar.map { lookupLocal($0) }
        let savedIndex = lookupLocal(stmt.indexVar)

        defer {
            restoreLocal(stmt.elementVar, value: savedElement)
            if let valueVar = stmt.valueVar {
                restoreLocal(valueVar, value: savedValue!)
            }
            restoreLocal(stmt.indexVar, value: savedIndex)
        }

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
                                        payload: element.value ?? .null, index: i + 1)
                if let final = handleLoopResult(result) {
                    return final
                }
            }
        case .table(let table):
            for (i, entry) in table.elements.enumerated() {
                let result = try await interpBody(stmt, element: .string(entry.key),
                                                  payload: entry.value, index: i + 1)
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
        case .string(let string):
            for (i, character) in string.enumerated() {
                let result = try await interpBody(stmt, element: .string(String(character)),
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
    ///
    private func interpBody(_ stmt: ParsedForEachStmt, element: ProgramValue,
                            payload: ProgramValue, index: Int) async throws -> InterpResult {

        // Assign values to the loop identifiers.
        assignLocal(stmt.elementVar, value: element)
        if let valueVar = stmt.valueVar {
            assignLocal(valueVar, value: payload)
        }
        assignLocal(stmt.indexVar, value: .integer(index))

        // Interpret the body.
        let result = try await interpStmtList(stmt.body)
        return result
    }

    /// Handle the end of loop result.
    ///
    private func handleLoopResult(_ result: InterpResult) -> InterpResult? {

        switch result {

        case .okay, .continuing:
            return nil          // Keep looping

        case .breaking:
            return .okay        // Consume break.

        case .returning:
            return result       // Propagate return.

        case .error:
            return result       // Propagate error.
        }
    }
}

extension GedcomNode {

    /// Return a GedcomNode and descendants in pre-order (for use in foreach statements).
    ///
    func preorderNodes() -> [GedcomNode] {

        var result: [GedcomNode] = []
        visit(self)
        return result

        func visit(_ node: GedcomNode) {  // Internal func that visits a node.
            result.append(node)
            var child = node.kid
            while let current = child {
                visit(current)
                child = current.sib
            }
        }
    }
}
