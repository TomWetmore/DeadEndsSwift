//
//  BuiltinNewList.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 5/5/26.
//  Last changed on 5 May 2026.
//

import Foundation

extension Program {

    /// Return the children of a person or family as a List<ProgramValue>.
    func builtinChildrenList(_ args: [ParsedExpr]) throws -> ProgramValue {

        let line = args[0].line
        var children = [Person]()

        switch try evaluate(args[0]) {
        case .person(let person):
            children = person.children(in: recordIndex)
        case .family(let family):
            children = family.children(in: recordIndex)
        case .null:
            return .null

        default:
            throw RuntimeError.invalidArguments("children: arg must be a person or family",
                                                line: line)
        }
        let result = List(children.map { ProgramValue.person($0) })
        return .list(result)
    }
}

struct ParsedForListStatement { // TODO: MOVE TO THE RIGHT PLACE.

    let listExpr: ParsedExpr
    let elementVar: String
    let indexVar: String
    let body: [ParsedStatement]
    let line: Int
}

extension Program {

    /// forlist(list, element, count)
    func interpForListStatement(_ statement: ParsedForListStatement) throws -> InterpResult {

        let list = try evaluateList(statement.listExpr, errMessage: "forlist: first arg must be a list")
        
        var index = 1
        for element in list {
            assignToSymbol(statement.elementVar, value: element)
            assignToSymbol(statement.indexVar, value: .integer(index))
            index += 1

            let result = try interpStmtList(statement.body)
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
 func interpForspousesStmt(_ stmt: ParsedForspousesStmt) throws -> InterpResult {

     let person = try evaluatePerson(stmt.personExpr, errMessage: "forspouses: first arg must be a person")
     let spouseFamilies = person.spousesWithFamilies(in: self.recordIndex)
     var index = 1
     for pair in spouseFamilies {
         assignToSymbol(stmt.spouseVar, value: .person(pair.spouse))
         assignToSymbol(stmt.familyVar, value: .family(pair.family))
         assignToSymbol(stmt.indexVar, value: .integer(index))
         index += 1

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
 */
