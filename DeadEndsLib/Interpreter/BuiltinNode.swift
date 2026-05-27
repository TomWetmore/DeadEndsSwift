//
//  BuiltinNode.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 5/26/26.
//  Last changed on 26 May 2026.
//
//  This file has the built-in methods for Gedcom
//  nodes.


import Foundation

/// Gedcom node properties.
extension Program {

    /// Returns the key of a node; returns .null if the node is nil or does not have a key.
    func builtInKey(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let node = try await evaluateGedcomNodeOpt(args[0], errMsg: "key: arg must be a node")
        if let node = node, let key = node.key {
            return .string(key)
        }
        return .null
    }

    /// Built-in that returns the tag of a node.
    func bltinTag(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let node = try await evaluateGedcomNodeOpt(args[0], errMsg: "tag: arg must be a node")
        if let node = node {
            return .string(node.tag)
        }
        return .null
    }

    /// Built-in that returns the value of a node; returns .nll
    func bltinVal(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let node = try await evaluateGedcomNodeOpt(args[0], errMsg: "value: arg must be a node")
        if let node = node, let val = node.val {
            return .string(val)
        }
        return .null
    }

    /// Built-in that returns the level of a node; returns .null if the node .null.
    func bltinLev(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let node = try await evaluateGedcomNodeOpt(args[0], errMsg: "level: arg must be a node")
        if let node = node {
            return .integer(node.lev)
        }
        return .null
    }

    /// Built-in that returns the kid of a node; returns .null if is null or has no kid.
    func bltinKid(_ args: [ParsedExpr]) async throws -> ProgramValue {
        
        let node = try await evaluateGedcomNodeOpt(args[0], errMsg: "child: arg must be a node")
        if let node = node, let kid = node.kid {
            return .gnode(kid)
        }
        return .null
    }

    /// Returns the sib of a node; returns .null if it is nil or has no sib.
    func bltinSib(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let node = try await evaluateGedcomNodeOpt(args[0],
                                errMsg: "sibling: arg must be a node")
        if let node = node, let sib = node.sib {
            return .gnode(sib)
        }
        return .null
    }

    /// Returns the dad of a node; returns .null if it is nil or has no dad.
    func bltinDad(_ args: [ParsedExpr]) async throws -> ProgramValue {
        
        let node = try await evaluateGedcomNodeOpt(args[0],
                                errMsg: "dad: arg must be a node")
        if let node = node, let par = node.dad {
            return .gnode(par)
        }
        return .null
    }

    /// Returns the first kid of a node that has a given tag; returns .null if there
    /// isn't one.
    /// kidwithtag(node, string) -> node?
    func bltinKidWithTag(_ args: [ParsedExpr]) async throws -> ProgramValue {

        guard let node =
            try await evaluateGedcomNodeOpt(args[0],
                            errMsg: "kidwithtag: 1st arg must be a node") else {
            return .null
        }
        let tag = try await evaluateString(args[1],
                                errMsg: "kidwithtag: 2nd arg must be a tag string")
        guard let kid = node.kid(withTag: tag) else {
            return .null
        }
        return .gnode(kid)
    }

    /// Returns the list of nodes that are kids of the given node and have a given tag.
    /// kidswithtag(node, string) -> list<node>
    func bltinKidsWithTag(_ args: [ParsedExpr]) async throws -> ProgramValue {

        guard let node =
                try await evaluateGedcomNodeOpt(args[0], errMsg: "kidswithtag: 1st arg must be a node") else {
            return .null
        }
        let tag = try await evaluateString(args[1], errMsg: "kidswithtag: 2nd arg must be a tag string")
        let list = List()
        for kid in node.kids(withTag: tag) {
            list.append(.gnode(kid))
        }
        return .list(list)
    }
}
