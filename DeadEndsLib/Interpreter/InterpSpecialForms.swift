//
//  InterpSpecialForms.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 5/1/26.
//  Last changed on 6 May 2026.
//

import Foundation

extension Program {

    /// Interpret a for list statement.
    func interpForList(_ stmt: ParsedForListStmt) throws -> InterpResult {

        let list = try evaluateList(stmt.listExpr, errMessage: "forlist: first arg must be a list or person set")

        for (i, value) in list.enumerated() {
            assignToSymbol(stmt.elementVar, value: value)
            assignToSymbol(stmt.indexVar, value: .integer(i+1))

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

    /// Interpret a forindiset statement.
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

//    func interpForspousesStmt(_ stmt: ParsedForspousesStmt) throws -> InterpResult {
//        
//        let person = try evaluatePerson(stmt.personExpr, errMessage: "forspouses: first arg must be a person")
//        let spouseFamilies = person.spousesWithFamilies(in: self.recordIndex)
//        var index = 1
//        for pair in spouseFamilies {
//            assignToSymbol(stmt.spouseVar, value: .person(pair.spouse))
//            assignToSymbol(stmt.familyVar, value: .family(pair.family))
//            assignToSymbol(stmt.indexVar, value: .integer(index))
//            index += 1
//
//            let result = try interpStmtList(stmt.body)
//            switch result {
//            case .okay:
//                continue
//            case .continuing:
//                continue
//            case .breaking:
//                return .okay
//            case .returning:
//                return result
//            case .error:
//                return result
//            }
//        }
//        return .okay
//    }
}
