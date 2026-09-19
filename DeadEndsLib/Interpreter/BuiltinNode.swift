//
//  BuiltinNode.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 26 May 2026.
//  Last changed on 19 September 2026.
//
//  This file has the built-in methods for Gedcom nodes.


import Foundation

/// Gedcom node properties.
extension Program {

    /// Built-in that returns the key of a person, family, or a root node.
    /// key(person|family|gnode|null) -> string|null

    func bltinKey(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let line = args[0].line
        let value = try await evaluate(args[0])
        let node: GedcomNode

        switch value {

        case .person(let person): node = person.root

        case .family(let family): node = family.root

        case .gnode(let gnode): node = gnode

        case .null: return .null

        default: throw RuntimeError("key: arg must be a record or root node", line: line)
        }
        guard let key = node.key else {
            throw RuntimeError("key: arg must be a record or root node", line: line)
        }
        return .string(key)
    }

    /// Built-in that returns the tag of a node.
    /// tag(node|null) -> string|null

    func bltinTag(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let node = try await evalGedcomNodeOpt(args[0], errMsg: "tag: arg must be a node")
        if let node = node {
            return .string(node.tag)
        }
        return .null
    }

    /// Built-in that returns the value of a node; returns null if value is null.
    /// val(node|null) -> string|null

    func bltinVal(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let node = try await evalGedcomNodeOpt(args[0], errMsg: "val: arg must be a node")
        if let node = node, let val = node.val {
            return .string(val)
        }
        return .null
    }

    /// Built-in that returns the level of a node; returns null if the the node is null.
    /// level(node|null) -> int|null

    func bltinLev(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let node = try await evalGedcomNodeOpt(args[0], errMsg: "lev: arg must be a node")
        if let node = node {
            return .integer(node.lev)
        }
        return .null
    }

    /// Built-in that returns the kid (first child) of a node; returns null if the node is null or
    /// there is no kid.
    /// kid(node|null) -> node|null

    func bltinKid(_ args: [ParsedExpr]) async throws -> ProgramValue {
        
        let node = try await evalGedcomNodeOpt(args[0], errMsg: "kid: arg must be a node")
        if let node = node, let kid = node.kid {
            return .gnode(kid)
        }
        return .null
    }

    /// Built-in that returns the sib (next sibling) of a node; returns null if the node is null
    /// or there is no sib.
    /// sib(node|null) -> node|null

    func bltinSib(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let node = try await evalGedcomNodeOpt(args[0],
                                errMsg: "sib: arg must be a node")
        if let node = node, let sib = node.sib {
            return .gnode(sib)
        }
        return .null
    }

    /// Builtin that returns the dad (parent) of a node; returns null if the node is null or
    /// has no dad.
    /// dad(node|null) -> node|null

    func bltinDad(_ args: [ParsedExpr]) async throws -> ProgramValue {
        
        let node = try await evalGedcomNodeOpt(args[0],
                                errMsg: "dad: arg must be a node")
        if let node = node, let par = node.dad {
            return .gnode(par)
        }
        return .null
    }

    /// Built-in that returns the list of kids of a node.
    /// kids(node|null) -> list<node>

    func bltinKids(_ args: [ParsedExpr]) async throws -> ProgramValue {

        guard let node = try await evalGedcomNodeOpt(args[0], errMsg: "kids: arg must be a node")
        else { return .emptyList }
        return .list(ListValue(node.kids.map { ProgramValue.gnode($0) }))
    }

    /// Built-in that returns the list of sibs of a node.
    /// sibs(node|null) -> list<node>

    func bltinSibs(_ args: [ParsedExpr]) async throws -> ProgramValue {

        guard let node = try await evalGedcomNodeOpt(args[0], errMsg: "sibs: arg must be a node")
        else { return .emptyList }
        return .list(ListValue(node.sibs.map { ProgramValue.gnode($0) }))
    }

    /// Built-in that returns the first kid of a node with a given tag; returns null if none.
    /// kidwithtag(node|null, string) -> node|null

    func bltinKidWithTag(_ args: [ParsedExpr]) async throws -> ProgramValue {

        guard let node =
            try await evalGedcomNodeOpt(args[0],
                            errMsg: "kidwithtag: 1st arg must be a node") else {
            return .null
        }
        let tag = try await evalString(args[1],
                                errMsg: "kidwithtag: 2nd arg must be a tag string")
        guard let kid = node.kid(withTag: tag) else {
            return .null
        }
        return .gnode(kid)
    }

    /// Returns the list of nodes that are kids of the given node and have a given tag.
    /// kidswithtag(node|null, string) -> list<node>

    func bltinKidsWithTag(_ args: [ParsedExpr]) async throws -> ProgramValue {
        guard let node =
                try await evalGedcomNodeOpt(args[0],
                                errMsg: "kidswithtag: 1st arg must be a node")
        else {
            return .emptyList
        }
        let tag = try await evalString(args[1],
                                errMsg: "kidswithtag: 2nd arg must be a tag string")

        return .list(ListValue(node.kids(withTag: tag).map(ProgramValue.gnode)))
    }
}
