//
//  Builtin.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 11 April 2026.
//  Last changed on 3 May 2026.
//

import Foundation

extension Program {

    /// Structure that holds the builtin functions.
    struct Builtin {
        
        let minArgs: Int
        let maxArgs: Int
        let function: ([ParsedExpr]) throws -> ProgramValue
    }

    /// Build the array of built-in functions.
    func setupBuiltins() {
        builtins = [
            "d":    Builtin(minArgs: 1, maxArgs: 1) { try self.builtinD($0) },
            "nl":   Builtin(minArgs: 0, maxArgs: 0) { try self.builtinNl($0) },
            "set":  Builtin(minArgs: 2, maxArgs: 2) { try self.builtinSet($0) },

            // Arithmetic operators.
            "add":  Builtin(minArgs: 2, maxArgs: 2) { try self.builtinAdd($0) },
            "sub":  Builtin(minArgs: 2, maxArgs: 2) { try self.builtinSub($0) },
            "mul":  Builtin(minArgs: 2, maxArgs: 2) { try self.builtinMul($0) },
            "div":  Builtin(minArgs: 2, maxArgs: 2) { try self.builtinDiv($0) },
            "mod":  Builtin(minArgs: 2, maxArgs: 2) { try self.builtinMod($0) },
            "neg":  Builtin(minArgs: 1, maxArgs: 1) { try self.builtinNeg($0) },

            // Increment and decrement operators.
            "incr": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinIncr($0) },
            "decr": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinDecr($0) },

            // Comparison operators.
            "eq": Builtin(minArgs: 2, maxArgs: 2) { try self.builtinEq($0) },
            "ne": Builtin(minArgs: 2, maxArgs: 2) { try self.builtinNe($0) },
            "lt": Builtin(minArgs: 2, maxArgs: 2) { try self.builtinLt($0) },
            "le": Builtin(minArgs: 2, maxArgs: 2) { try self.builtinLe($0) },
            "gt": Builtin(minArgs: 2, maxArgs: 2) { try self.builtinGt($0) },
            "ge": Builtin(minArgs: 2, maxArgs: 2) { try self.builtinGe($0) },

            // Logical operators.
            "and": Builtin(minArgs: 1, maxArgs: 32) { try self.builtinAnd($0) },
            "or":  Builtin(minArgs: 1, maxArgs: 32) { try self.builtinOr($0) },
            "not": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinNot($0) },

            // Gedcom node properties.
            "key": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinKey($0) },
            "tag": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinTag($0) },
            "value": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinValue($0) },
            "level": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinLevel($0) },
            "child": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinChild($0) },
            "sibling": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinSibling($0) },
            "parent": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinParent($0) },

            // Person operations.
            "indi": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinIndi($0) },
            "name": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinName($0) },
            "givens": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinGivens($0) },
            "surname": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinSurname($0) },
            "birth": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinBirth($0) },
            "death": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinDeath($0) },
            "father": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinFather($0) },
            "mother": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinMother($0) },

            // Event operations.
            "date":  Builtin(minArgs: 1, maxArgs: 1) { try self.builtinDate($0) },
            "place": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinPlace($0) },

            // Generic functions on lists, tables and person sets.
            "empty":  Builtin(minArgs: 1, maxArgs: 1) { try self.builtinEmpty($0) },
            "length": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinLength($0) },
            "clear":  Builtin(minArgs: 1, maxArgs: 1) { try self.builtinClear($0) },

            // List operations; the length and empty builtins are generic.
            "list":    Builtin(minArgs: 1, maxArgs: 1) { try self.builtinList($0) },
            "append":  Builtin(minArgs: 2, maxArgs: 2) { try self.builtinAppend($0) },
            "prepend": Builtin(minArgs: 2, maxArgs: 2) { try self.builtinPrepend($0) },
            "push":    Builtin(minArgs: 2, maxArgs: 2) { try self.builtinAppend($0) },
            "pop":     Builtin(minArgs: 1, maxArgs: 1) { try self.builtinRemoveFirst($0) },
            "enqueue": Builtin(minArgs: 2, maxArgs: 2) { try self.builtinAppend($0) },
            "dequeue": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinRemoveFirst($0) },

            // Table operations.
            "table":  Builtin(minArgs: 1, maxArgs: 1) { try self.builtinTable($0) },
            "insert": Builtin(minArgs: 3, maxArgs: 3) { try self.builtinInsert($0) },
            "lookup": Builtin(minArgs: 2, maxArgs: 2) { try self.builtinLookup($0) },

            // Person set operations.
            "indiset": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinIndiset($0) },
            "addtoset" : Builtin(minArgs: 3, maxArgs: 3) { try self.builtinAddtoset($0) },
            "union"    : Builtin(minArgs: 2, maxArgs: 2) { try self.builtinUnion($0) },
            "parentset" : Builtin(minArgs: 1, maxArgs: 1) { try self.builtinParentset($0) },
            "childset" : Builtin(minArgs: 1, maxArgs: 1) { try self.builtinChildset($0) },
            // Lots of iterators are not yet implemented.

            // Meta operations.
            "showframe": Builtin(minArgs: 0, maxArgs: 0) { try self.builtinShowFrame($0) },
            "showstack": Builtin(minArgs: 0, maxArgs: 0) { try self.builtinShowStack($0) },
            "valueof": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinValueOf($0) },
        ]
    }
}

extension Program {
    
    /// builtinD returns an integer as a string.
    func builtinD(_ args: [ParsedExpr]) throws -> ProgramValue {
        let value = try self.evaluate(args[0])
        guard case let .integer(integer) = value else {
            throw RuntimeError.typeMismatch("d() requires an integer argument",
                                            line: args[0].line)
        }
        return .string(String(integer))
    }
    
    /// Returns a newline character.
    func builtinNl(_ args: [ParsedExpr]) throws -> ProgramValue {
        return .string("\n")
    }
    
    /// Assignment 'statement' of the scripting language; side effect only.
    func builtinSet(_ args: [ParsedExpr]) throws -> ProgramValue {
        guard case let .identifier(name) = args[0].kind else {
            throw RuntimeError.typeError("set() expects a variable as its first argument", line: args[0].line)
        }
        let value = try evaluate(args[1])
        assignToSymbol(name, value: value)
        return .null  // Side effect only.
    }
}

/// Gedcom node properties.
extension Program {

    /// Builtin that returns the key of a node; retuns .null if node dones not have a key
    func builtInKey(_ args: [ParsedExpr]) throws -> ProgramValue {
        let node = try evaluateGedcomNodeOpt(args[0], errMessage: "key: arg must be a node")
        if let node = node, let key = node.key {
            return .string(key)
        }
        return .null
    }

    /// Builtin that returns the tag of a node.
    func builtinTag(_ args: [ParsedExpr]) throws -> ProgramValue {
        let node = try evaluateGedcomNodeOpt(args[0], errMessage: "tag: arg must be a node")
        if let node = node {
            return .string(node.tag)
        }
        return .null
    }

    /// Builtin that returns the value of a node; returns .nll
    func builtinValue(_ args: [ParsedExpr]) throws -> ProgramValue {
        let node = try evaluateGedcomNodeOpt(args[0], errMessage: "value: arg must be a node")
        if let node = node, let val = node.val {
            return .string(val)
        }
        return .null
    }

    /// Builtin that returns the level of a node; returns .null if the node .null.
    func builtinLevel(_ args: [ParsedExpr]) throws -> ProgramValue {
        let node = try evaluateGedcomNodeOpt(args[0], errMessage: "level: arg must be a node")
        if let node = node {
            return .integer(node.lev)
        }
        return .null
    }

    /// Builtin that returns the child of a node; returns .null if is null or has no chold.
    func builtinChild(_ args: [ParsedExpr]) throws -> ProgramValue {
        let node = try evaluateGedcomNodeOpt(args[0], errMessage: "child: arg must be a node")
        if let node = node, let kid = node.kid {
            return .gnode(kid)
        }
        return .null
    }

    /// Builtin that returns the sibling of a node; returns .null of it is nil or has no sibling.
    func builtinSibling(_ args: [ParsedExpr]) throws -> ProgramValue {
        let node = try evaluateGedcomNodeOpt(args[0], errMessage: "sibling: arg must be a node")
        if let node = node, let sib = node.sib {
            return .gnode(sib)
        }
        return .null
    }

    /// Builtin that returns the parent of a node; returns .null if it is nil or has no parent.
    func builtinParent(_ args: [ParsedExpr]) throws -> ProgramValue {
        let node = try evaluateGedcomNodeOpt(args[0], errMessage: "parent: arg must be a node")
        if let node = node, let par = node.dad {
            return .gnode(par)
        }
        return .null
    }
}
