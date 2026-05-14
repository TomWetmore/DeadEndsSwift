//
//  Builtin.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 11 April 2026.
//  Last changed on 12 May 2026.
//

import Foundation

extension Program {

    /// Structure that holds the builtin functions.
    struct Builtin {
        
        let min: Int
        let max: Int
        let function: ([ParsedExpr]) throws -> ProgramValue
    }

    /// Build the array of built-in functions.
    func setupBuiltins() {
        
        builtins = [
            "d":    Builtin(min: 1, max: 1) { try self.bltinD($0)},
            "nl":   Builtin(min: 0, max: 0) { try self.bltinNl($0)},
            "set":  Builtin(min: 2, max: 2) { try self.bltinSet($0)},
            "ord":  Builtin(min: 1, max: 1) { try self.bltinOrd($0)},

            // Arithmetic operators.
            "add":  Builtin(min: 2, max: 2) { try self.bltinAdd($0)},
            "sub":  Builtin(min: 2, max: 2) { try self.bltinSub($0)},
            "mul":  Builtin(min: 2, max: 2) { try self.bltinMul($0)},
            "div":  Builtin(min: 2, max: 2) { try self.bltinDiv($0)},
            "mod":  Builtin(min: 2, max: 2) { try self.bltinMod($0)},
            "neg":  Builtin(min: 1, max: 1) { try self.bltinNeg($0)},

            // Increment and decrement operators.
            "incr": Builtin(min: 1, max: 1) { try self.bltinIncr($0)},
            "decr": Builtin(min: 1, max: 1) { try self.bltinDecr($0)},

            // Comparison operators.
            "eq": Builtin(min: 2, max: 2) { try self.bltinEq($0)},
            "ne": Builtin(min: 2, max: 2) { try self.bltinNe($0)},
            "lt": Builtin(min: 2, max: 2) { try self.bltinLt($0)},
            "le": Builtin(min: 2, max: 2) { try self.bltinLe($0)},
            "gt": Builtin(min: 2, max: 2) { try self.bltinGt($0)},
            "ge": Builtin(min: 2, max: 2) { try self.bltinGe($0)},

            // Logical operators.
            "and": Builtin(min: 1, max: 32) { try self.bltinAnd($0)},
            "or":  Builtin(min: 1, max: 32) { try self.bltinOr($0)},
            "not": Builtin(min: 1, max: 1) { try self.bltinNot($0)},

            // Gedcom node properties.
            "key":  Builtin(min: 1, max: 1) { try self.bltinKey($0)},
            "tag":  Builtin(min: 1, max: 1) { try self.bltinTag($0)},
            "val":  Builtin(min: 1, max: 1) { try self.bltinVal($0)},
            "lev":  Builtin(min: 1, max: 1) { try self.bltinLev($0)},
            "kid":  Builtin(min: 1, max: 1) { try self.bltinKid($0)},
            "sib":  Builtin(min: 1, max: 1) { try self.bltinSib($0)},
            "dad":  Builtin(min: 1, max: 1) { try self.bltinDad($0)},
            "root": Builtin(min: 1, max: 1) { try self.bltinRoot($0)},

            // Person operations.
            "person":   Builtin(min: 1, max: 1) { try self.bltinPerson($0)},
            "name":     Builtin(min: 1, max: 1) { try self.bltinName($0)},
            "fullname": Builtin(min: 4, max: 4) { try self.bltinFullName($0)},
            "givens":   Builtin(min: 1, max: 1) { try self.bltinGivens($0)},
            "surname":  Builtin(min: 1, max: 1) { try self.bltinSurname($0)},
            "birth":    Builtin(min: 1, max: 1) { try self.bltinBirth($0)},
            "death":    Builtin(min: 1, max: 1) { try self.bltinDeath($0)},
            "father":   Builtin(min: 1, max: 1) { try self.bltinFather($0)},
            "mother":   Builtin(min: 1, max: 1) { try self.bltinMother($0)},
            "families": Builtin(min: 1, max: 1) { try self.builtinFamilyList($0)},
            "allpersons":  Builtin(min: 0, max: 0) { try self.bltinAllPersons($0)},
            "male":     Builtin(min: 1, max: 1) { try self.bltinMale($0)},
            "female":   Builtin(min: 1, max: 1) { try self.bltinWife($0)},

            "allfamilies": Builtin(min: 0, max: 0) { try self.bltinAllFamilies($0)},

            /// Generic operations on persons and families.
            "husband":  Builtin(min: 1, max: 1) { try self.bltinHusband($0)},
            "wife":     Builtin(min: 1, max: 1) { try self.bltinWife($0)},
            "husbands": Builtin(min: 1, max: 1) { try self.bltinHusbands($0)},
            "wives":    Builtin(min: 1, max: 1) { try self.bltinWives($0)},
            "children": Builtin(min: 1, max: 1) { try self.bltinChildren($0)},
            "spouses":  Builtin(min: 1, max: 1) { try self.bltinSpouses($0)},
            "parents":  Builtin(min: 1, max: 1) { try self.bltinParents($0)},
            "siblings": Builtin(min: 1, max: 1) { try self.bltinSiblings($0)},

            // Event operations.
            "date":  Builtin(min: 1, max: 1) { try self.bltinDate($0)},
            "place": Builtin(min: 1, max: 1) { try self.bltinPlace($0)},

            // Generic operations on lists, tables and person sets.
            "empty":  Builtin(min: 1, max: 1) { try self.bltinEmpty($0)},
            "length": Builtin(min: 1, max: 1) { try self.bltinLength($0)},
            "clear":  Builtin(min: 1, max: 1) { try self.bltinClear($0)},
            "subscript": Builtin(min: 2, max: 2) { try self.bltinSubscript($0)},

            "traverse":  Builtin(min: 1, max: 1) { try self.bltinNodes($0)},

            // List operations; the length and empty builtins are generic.
            "list":    Builtin(min: 0, max: 0) { try self.bltinList($0)},
            "append":  Builtin(min: 2, max: 2) { try self.bltinAppend($0)},
            "prepend": Builtin(min: 2, max: 2) { try self.bltinPrepend($0)},
            "push":    Builtin(min: 2, max: 2) { try self.bltinAppend($0)},
            "pop":     Builtin(min: 1, max: 1) { try self.bltinRemoveFirst($0)},
            "enqueue": Builtin(min: 2, max: 2) { try self.bltinAppend($0)},
            "dequeue": Builtin(min: 1, max: 1) { try self.bltinRemoveFirst($0)},

            // Table operations.
            "table":  Builtin(min: 0, max: 0) { try self.bltinTable($0)},
            "insert": Builtin(min: 3, max: 3) { try self.bltinInsert($0)},
            "lookup": Builtin(min: 2, max: 2) { try self.bltinLookup($0)},

            // Person set operations.
            "personset":     Builtin(min: 0, max: 0) { try self.bltinPersonSet($0)},
            "addtoset" :     Builtin(min: 2, max: 3) { try self.bltinAddToSet($0)},
            "removefromset": Builtin(min: 2, max: 2) { try self.bltinDeleteFromSet($0)},
            "union"    :     Builtin(min: 2, max: 2) { try self.bltinUnion($0)},
            "intersect":     Builtin(min: 2, max: 2) { try self.bltinIntersect($0)},
            "difference":    Builtin(min: 2, max: 2) { try self.bltinDifference($0)},
            "parentset" :    Builtin(min: 1, max: 1) { try self.bltinParentSet($0)},
            "childset" :     Builtin(min: 1, max: 1) { try self.bltinChildSet($0)},
            "spouseset":     Builtin(min: 1, max: 1) { try self.bltinSpouseSet($0)},
            "siblingset":    Builtin(min: 1, max: 1) { try self.bltinSiblingSet($0)},
            "ancestorset":   Builtin(min: 1, max: 1) { try self.bltinAncestorSet($0)},
            "descendentset": Builtin(min: 1, max: 1) { try self.bltinDescendentSet($0)},
            "namesort":      Builtin(min: 1, max: 1) { try self.bltinNameSort($0)},
            "keysort":       Builtin(min: 1, max: 1) { try self.bltinKeySort($0)},

            // String operations.
            "strcmp": Builtin(min: 2, max: 2) { try self.bltinStrcmp($0)},

            // Meta operations.
            "showframe": Builtin(min: 0, max: 0) { try self.bltinShowFrame($0)},
            "showstack": Builtin(min: 0, max: 0) { try self.bltinShowStack($0)},
            "valueof":   Builtin(min: 1, max: 1) { try self.bltinValueOf($0)},
        ]
    }
}

extension Program {
    
    /// Returns an integer as a string.
    func bltinD(_ args: [ParsedExpr]) throws -> ProgramValue {
        let value = try self.evaluate(args[0])
        guard case let .integer(integer) = value else {
            throw RuntimeError("d: arg must be an integer", line: args[0].line)
        }
        return .string(String(integer))
    }
    
    /// Returns a newline character.
    func bltinNl(_ args: [ParsedExpr]) throws -> ProgramValue {
        return .string("\n")
    }
    
    /// Assignment 'statement' of the scripting language; side effect only.
    func bltinSet(_ args: [ParsedExpr]) throws -> ProgramValue {
        guard case let .identifier(name) = args[0].kind else {
            throw RuntimeError("set() expects a variable as its first argument", line: args[0].line)
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
        let node = try evaluateGedcomNodeOpt(args[0], errMsg: "key: arg must be a node")
        if let node = node, let key = node.key {
            return .string(key)
        }
        return .null
    }

    /// Builtin that returns the tag of a node.
    func bltinTag(_ args: [ParsedExpr]) throws -> ProgramValue {
        let node = try evaluateGedcomNodeOpt(args[0], errMsg: "tag: arg must be a node")
        if let node = node {
            return .string(node.tag)
        }
        return .null
    }

    /// Builtin that returns the value of a node; returns .nll
    func bltinVal(_ args: [ParsedExpr]) throws -> ProgramValue {
        let node = try evaluateGedcomNodeOpt(args[0], errMsg: "value: arg must be a node")
        if let node = node, let val = node.val {
            return .string(val)
        }
        return .null
    }

    /// Builtin that returns the level of a node; returns .null if the node .null.
    func bltinLev(_ args: [ParsedExpr]) throws -> ProgramValue {
        let node = try evaluateGedcomNodeOpt(args[0], errMsg: "level: arg must be a node")
        if let node = node {
            return .integer(node.lev)
        }
        return .null
    }

    /// Builtin that returns the child of a node; returns .null if is null or has no chold.
    func bltinKid(_ args: [ParsedExpr]) throws -> ProgramValue {
        let node = try evaluateGedcomNodeOpt(args[0], errMsg: "child: arg must be a node")
        if let node = node, let kid = node.kid {
            return .gnode(kid)
        }
        return .null
    }

    /// Builtin that returns the sibling of a node; returns .null of it is nil or has no sibling.
    func bltinSib(_ args: [ParsedExpr]) throws -> ProgramValue {
        let node = try evaluateGedcomNodeOpt(args[0], errMsg: "sibling: arg must be a node")
        if let node = node, let sib = node.sib {
            return .gnode(sib)
        }
        return .null
    }

    /// Builtin that returns the parent of a node; returns .null if it is nil or has no parent.
    func bltinDad(_ args: [ParsedExpr]) throws -> ProgramValue {
        let node = try evaluateGedcomNodeOpt(args[0], errMsg: "parent: arg must be a node")
        if let node = node, let par = node.dad {
            return .gnode(par)
        }
        return .null
    }
}
