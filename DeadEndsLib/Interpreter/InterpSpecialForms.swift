//
//  InterpSpecialForms.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 5/1/26.
//  Last changed on 1 May 2026.
//

import Foundation

extension Program {

    /// Interpret a for list statement.
    func interpForList(_ stmt: ParsedForListStmt) throws -> InterpResult {

        let list = try evaluateList(stmt.listExpr, errMessage: "forlist: first arg must be a list")

        for (i, value) in list.enumerated() {
            assignToSymbol(stmt.elementVar, value: value)
            assignToSymbol(stmt.indexVar, value: .integer(i))

            let result = try interpStmtList(stmt.body)

            switch result {
            case .okay:
                continue
            case .continuing:
                continue
            case .breaking:
                return .okay
            case .returning:
                return result
            case .error:
                return result
            }
        }

        return .okay
    }

    /// Interpret a for indiset statement.
    func interpForIndiset(_ stmt: ParsedForIndisetStmt) throws -> InterpResult {

        let set = try evaluatePersonSet(stmt.indisetExpr, errMessage: "forindiset: first arg must be an indiset")

        for (i, element) in set.enumerated() {
            assignToSymbol(stmt.indiVar, value: .person(element.person)) // Person in element.
            assignToSymbol(stmt.valueVar, value: element.payload ?? .null) // Associated value.
            assignToSymbol(stmt.indexVar, value: .integer(i)) // Index of element.

            let result = try interpStmtList(stmt.body)

            switch result {
            case .okay:
                continue
            case .continuing:
                continue
            case .breaking:
                return .okay
            case .returning:
                return result
            case .error:
                return result
            }
        }

        return .okay
    }
}

    /*
     let indisetExpr: ParsedExpr (check!)
     let indiVar: String
     let valueVar: String
     let indexVar: String
     let body: [ParsedStatement]
     let line: Int
     */

/*
 proc main () {
    list(list)
    append(list, 1)
    append(list, 2)
    append(list, 3)
    forlist
 (
 list

 ,
 v
 ,
 i
 )
 {
        d(i) " " d(v) "\n"
    }
 }
 */
