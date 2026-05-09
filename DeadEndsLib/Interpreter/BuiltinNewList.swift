//
//  BuiltinNewList.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 5/5/26.
//  Last changed on 8 May 2026.
//

import Foundation

extension Program {

    /// Return the children of a person or family as a List.
    func builtinChildList(_ args: [ParsedExpr]) throws -> ProgramValue {

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
        return .list(List(children.map { ProgramValue.person($0) }))
    }

    /// Return the list of husbands of a person or family.
    func builtinHusbandList(_ args: [ParsedExpr]) throws -> ProgramValue {

        let line = args[0].line
        var husbands = [Person]()

        switch try evaluate(args[0]) {
        case .person(let person):
            husbands = person.husbands(in: recordIndex)
        case .family(let family):
            husbands = family.husbands(in: recordIndex)
        case .null:
            return .null
        default:
            throw RuntimeError.invalidArguments("husbands: arg must be a person or family", line: line)
        }
        return .list(List(husbands.map { ProgramValue.person($0)}))
    }

    /// Return the list of wives of a person or family.
    func builtinWifeList(_ args: [ParsedExpr]) throws -> ProgramValue {
        let line = args[0].line
        var wives = [Person]()

        switch try evaluate(args[0]) {
        case .person(let person):
            wives = person.wives(in: recordIndex)
        case .family(let family):
            wives = family.wives(in: recordIndex)
        case .null:
            return .null
        default:
            throw RuntimeError.invalidArguments("wives: arg must be a person or family", line: line)
        }
        return .list(List(wives.map { ProgramValue.person($0)}))
    }

    /// Return the list of siblings of a person.
    func builtinSiblingList(_ args: [ParsedExpr]) throws -> ProgramValue {

        let line = args[0].line
        var siblings = [Person]()

        switch try evaluate(args[0]) {
        case .person(let person):
            siblings = person.siblings(in: recordIndex)
        case .null:
            return .null
        default:
            throw RuntimeError.invalidArguments("siblings: arg must be a person", line: line)
        }
        return .list(List(siblings.map { ProgramValue.person($0)}))
    }

    /// Return the list of spouses of a person or family.
    func builtinSpouseList(_ args: [ParsedExpr]) throws -> ProgramValue {

        let line = args[0].line
        var spouses = [Person]()

        switch try evaluate(args[0]) {
        case .person(let person):
            spouses = person.spouses(in: recordIndex)
        case .family(let family):
            spouses = family.spouses(in: recordIndex)
        case .null:
            return .null
        default:
            throw RuntimeError.invalidArguments("spouses: arg must be a person or family",
                                                line: line)
        }
        return .list(List(spouses.map { ProgramValue.person($0) }))
    }

    /// Return the list of parents of a person or family (the spouses).
    func builtinParentList(_ args: [ParsedExpr]) throws -> ProgramValue {

        let line = args[0].line
        var parents = [Person]()

        switch try evaluate(args[0]) {
        case .person(let person):
            parents = person.parents(in: recordIndex)
        case .family(let family):
            parents = family.spouses(in: recordIndex) // Define parents of a family and the spouses.
        case .null:
            return .null
        default:
            throw RuntimeError.invalidSyntax("parents: arg must be a person", line: line)
        }
        return .list(List(parents.map { ProgramValue.person($0) }))
    }

    /// Return the list of families a person is in as a spouse.
    /// families(person) -> .list(Family)
    func builtinFamilyList(_ args: [ParsedExpr]) throws -> ProgramValue {
        let line = args[0].line
        var families = [Family]()

        switch try evaluate(args[0]) {
        case .person(let person):
            families = person.spouseFamilies(in: recordIndex)
        case .null:
            return .null
        default:
            throw RuntimeError.invalidArguments("spouses: arg must be a person", line: line)
        }
        let result = List(families.map { ProgramValue.family($0)})
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
