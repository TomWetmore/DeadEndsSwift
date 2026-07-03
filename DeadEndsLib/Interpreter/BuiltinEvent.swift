//
//  BuiltinEvent.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 10 May 2026.
//  Last changed on 3 July 2026.
//

import Foundation

/// Event realted built-ins.
extension Program {

    /// Return the first birth event of a person.
    /// birth(person) -> .gnode or .null
    func bltinBirth(_ args: [ParsedExpr]) async throws -> ProgramValue {
        
        guard let person = try await evalPersonOpt(args[0], errMsg: "birth: arg must be a person")
        else { return .null }

        guard let birth = person.kid(withTag: GedcomTag.BIRT) else { return .null }
        return .gnode(birth)
    }

    /// Return the first death event of a person
    /// death(person) -> .gnode or .null
    func bltinDeath(_ args: [ParsedExpr]) async throws -> ProgramValue {

        guard let person = try await evalPersonOpt(args[0], errMsg: "death: arg must be a person")
        else { return .null }
        
        guard let death = person.kid(withTag: GedcomTag.DEAT) else { return .null }
        return .gnode(death)
    }

    /// Return the first burial event of a person.
    /// burial(person) -> .gnode or .null
    func builtinBurial(_ args: [ParsedExpr]) async throws -> ProgramValue {

        guard let person = try await evalPersonOpt(args[0], errMsg: "burial: arg must be a person")
        else { return .null }

        guard let burial = person.kid(withTag: GedcomTag.BURI) else { return .null }
        return .gnode(burial)    }

    /// Return the first baptism event of a person.
    /// baptism(person) -> .gnode or .null
    func builtinBaptism(_ args: [ParsedExpr]) throws -> ProgramValue {
        return try extractPersonEvent(from: args[0], tag: "BAPM", functionName: "baptism")
    }
}

extension Program {

    ///  Return the value of the first date node under an event node.
    ///  date(Node<Event>) --> String
    func bltinDate(_ arg: [ParsedExpr]) async throws -> ProgramValue {
        let node = try await evalGedcomNodeOpt(arg[0], errMsg: "date: arg must be a node")
        if let node = node, let date = node.kid(withTag: GedcomTag.DATE),
                                                let value = date.val {
            return .string(value)
        }
        return .null
    }

    /// Return the value of the first place node under an event node.
    func bltinPlace(_ arg: [ParsedExpr]) async throws -> ProgramValue {
        let node = try await evalGedcomNodeOpt(arg[0], errMsg: "place: arg must be a node")
        if let node = node, let place = node.kid(withTag: GedcomTag.PLAC),
           let value = place.val {
            return .string(value)
        }
        return .null
    }
}

