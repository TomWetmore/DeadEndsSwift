//
//  Builtin.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 11 April 2026.
//  Last changed on 9 May 2026.
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
            "d":    Builtin(min: 1, max: 1) { try self.builtinD($0) },
            "nl":   Builtin(min: 0, max: 0) { try self.builtinNl($0) },
            "set":  Builtin(min: 2, max: 2) { try self.builtinSet($0) },

            // Arithmetic operators.
            "add":  Builtin(min: 2, max: 2) { try self.builtinAdd($0) },
            "sub":  Builtin(min: 2, max: 2) { try self.builtinSub($0) },
            "mul":  Builtin(min: 2, max: 2) { try self.builtinMul($0) },
            "div":  Builtin(min: 2, max: 2) { try self.builtinDiv($0) },
            "mod":  Builtin(min: 2, max: 2) { try self.builtinMod($0) },
            "neg":  Builtin(min: 1, max: 1) { try self.builtinNeg($0) },

            // Increment and decrement operators.
            "incr": Builtin(min: 1, max: 1) { try self.builtinIncr($0) },
            "decr": Builtin(min: 1, max: 1) { try self.builtinDecr($0) },

            // Comparison operators.
            "eq": Builtin(min: 2, max: 2) { try self.builtinEq($0) },
            "ne": Builtin(min: 2, max: 2) { try self.builtinNe($0) },
            "lt": Builtin(min: 2, max: 2) { try self.builtinLt($0) },
            "le": Builtin(min: 2, max: 2) { try self.builtinLe($0) },
            "gt": Builtin(min: 2, max: 2) { try self.builtinGt($0) },
            "ge": Builtin(min: 2, max: 2) { try self.builtinGe($0) },

            // Logical operators.
            "and": Builtin(min: 1, max: 32) { try self.builtinAnd($0) },
            "or":  Builtin(min: 1, max: 32) { try self.builtinOr($0) },
            "not": Builtin(min: 1, max: 1) { try self.builtinNot($0) },

            // Gedcom node properties.
            "key":     Builtin(min: 1, max: 1) { try self.builtinKey($0) },
            "tag":     Builtin(min: 1, max: 1) { try self.builtinTag($0) },
            "value":   Builtin(min: 1, max: 1) { try self.builtinValue($0) },
            "level":   Builtin(min: 1, max: 1) { try self.bltinLevel($0) },
            "child":   Builtin(min: 1, max: 1) { try self.builtinChild($0) },
            "sibling": Builtin(min: 1, max: 1) { try self.builtinSibling($0) },
            "parent":  Builtin(min: 1, max: 1) { try self.builtinParent($0) },
            "root":    Builtin(min: 1, max: 1) { try self.builtinRoot($0) },

            // Person operations.
            "indi":     Builtin(min: 1, max: 1) { try self.builtinIndi($0) },
            "name":     Builtin(min: 1, max: 1) { try self.builtinName($0) },
            "givens":   Builtin(min: 1, max: 1) { try self.builtinGivens($0) },
            "surname":  Builtin(min: 1, max: 1) { try self.builtinSurname($0) },
            "birth":    Builtin(min: 1, max: 1) { try self.builtinBirth($0) },
            "death":    Builtin(min: 1, max: 1) { try self.builtinDeath($0) },
            "father":   Builtin(min: 1, max: 1) { try self.builtinFather($0) },
            "mother":   Builtin(min: 1, max: 1) { try self.builtinMother($0) },
            "families": Builtin(min: 1, max: 1) { try self.builtinFamilyList($0) },

            /// Generic functions on persons and families.
            "husband":  Builtin(min: 1, max: 1) { try self.builtinHusband($0) },
            "wife":     Builtin(min: 1, max: 1) { try self.builtinWife($0) },
            "husbands": Builtin(min: 1, max: 1) { try self.builtinHusbandList($0) },
            "wives":    Builtin(min: 1, max: 1) { try self.builtinWifeList($0) },
            "children": Builtin(min: 1, max: 1) { try self.builtinChildList($0) },
            "spouses":  Builtin(min: 1, max: 1) { try self.builtinSpouseList($0) },
            "parents":  Builtin(min: 1, max: 1) { try self.builtinParentList($0) },
            "siblings": Builtin(min: 1, max: 1) { try self.builtinSiblingList($0) },

            // Event operations.
            "date":  Builtin(min: 1, max: 1) { try self.builtinDate($0) },
            "place": Builtin(min: 1, max: 1) { try self.builtinPlace($0) },

            // Generic functions on lists, tables and person sets.
            "empty":  Builtin(min: 1, max: 1) { try self.builtinEmpty($0) },
            "length": Builtin(min: 1, max: 1) { try self.builtinLength($0) },
            "clear":  Builtin(min: 1, max: 1) { try self.builtinClear($0) },

            // List operations; the length and empty builtins are generic.
            "list":    Builtin(min: 0, max: 0) { try self.builtinList($0) },
            "append":  Builtin(min: 2, max: 2) { try self.builtinAppend($0) },
            "prepend": Builtin(min: 2, max: 2) { try self.builtinPrepend($0) },
            "push":    Builtin(min: 2, max: 2) { try self.builtinAppend($0) },
            "pop":     Builtin(min: 1, max: 1) { try self.builtinRemoveFirst($0) },
            "enqueue": Builtin(min: 2, max: 2) { try self.builtinAppend($0) },
            "dequeue": Builtin(min: 1, max: 1) { try self.builtinRemoveFirst($0) },

            // Table operations.
            "table":  Builtin(min: 1, max: 1) { try self.bltinTable($0) },
            "insert": Builtin(min: 3, max: 3) { try self.bltinInsert($0) },
            "lookup": Builtin(min: 2, max: 2) { try self.bltinLookup($0) },

            // Person set operations.
            "personset":    Builtin(min: 0, max: 0) { try self.bltinPersonSet($0)},
            "addtoset" :    Builtin(min: 3, max: 3) { try self.bltinAddToSet($0)},
            "removefromset": Builtin(min: 2, max: 2) { try self.bltinDeleteFromSet($0)},
            "union"    :    Builtin(min: 2, max: 2) { try self.bltinUnion($0)},
            "intersect":    Builtin(min: 2, max: 2) { try self.bltinIntersect($0)},
            "difference":   Builtin(min: 2, max: 2) { try self.bltinDifference($0)},
            "parentset" :   Builtin(min: 1, max: 1) { try self.bltinParentSet($0)},
            "childset" :    Builtin(min: 1, max: 1) { try self.bltinChildSet($0)},
            "spouseset":    Builtin(min: 1, max: 1) { try self.bltinSpouseSet($0)},
            "siblingset":   Builtin(min: 1, max: 1) { try self.bltinSiblingSet($0)},
            "ancestorset":  Builtin(min: 1, max: 1) { try self.bltinAncestorSet($0)},
            "descendorset": Builtin(min: 1, max: 1) { try self.bltinDescendentSet($0)},
            "namesort":     Builtin(min: 1, max: 1) { try self.bltinNameSort($0)},
            "keysort":      Builtin(min: 1, max: 1) { try self.bltinKeySort($0)},

            // Meta operations.
            "showframe": Builtin(min: 0, max: 0) { try self.builtinShowFrame($0)},
            "showstack": Builtin(min: 0, max: 0) { try self.builtinShowStack($0)},
            "valueof":   Builtin(min: 1, max: 1) { try self.builtinValueOf($0)},
        ]
    }
}

extension Program {
    
    /// Returns an integer as a string.
    func builtinD(_ args: [ParsedExpr]) throws -> ProgramValue {
        let value = try self.evaluate(args[0])
        guard case let .integer(integer) = value else {
            throw RuntimeError.typeMismatch("d: arg must be an integer", line: args[0].line)
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
        let node = try evaluateGedcomNodeOpt(args[0], errMsg: "key: arg must be a node")
        if let node = node, let key = node.key {
            return .string(key)
        }
        return .null
    }

    /// Builtin that returns the tag of a node.
    func builtinTag(_ args: [ParsedExpr]) throws -> ProgramValue {
        let node = try evaluateGedcomNodeOpt(args[0], errMsg: "tag: arg must be a node")
        if let node = node {
            return .string(node.tag)
        }
        return .null
    }

    /// Builtin that returns the value of a node; returns .nll
    func builtinValue(_ args: [ParsedExpr]) throws -> ProgramValue {
        let node = try evaluateGedcomNodeOpt(args[0], errMsg: "value: arg must be a node")
        if let node = node, let val = node.val {
            return .string(val)
        }
        return .null
    }

    /// Builtin that returns the level of a node; returns .null if the node .null.
    func bltinLevel(_ args: [ParsedExpr]) throws -> ProgramValue {
        let node = try evaluateGedcomNodeOpt(args[0], errMsg: "level: arg must be a node")
        if let node = node {
            return .integer(node.lev)
        }
        return .null
    }

    /// Builtin that returns the child of a node; returns .null if is null or has no chold.
    func builtinChild(_ args: [ParsedExpr]) throws -> ProgramValue {
        let node = try evaluateGedcomNodeOpt(args[0], errMsg: "child: arg must be a node")
        if let node = node, let kid = node.kid {
            return .gnode(kid)
        }
        return .null
    }

    /// Builtin that returns the sibling of a node; returns .null of it is nil or has no sibling.
    func builtinSibling(_ args: [ParsedExpr]) throws -> ProgramValue {
        let node = try evaluateGedcomNodeOpt(args[0], errMsg: "sibling: arg must be a node")
        if let node = node, let sib = node.sib {
            return .gnode(sib)
        }
        return .null
    }

    /// Builtin that returns the parent of a node; returns .null if it is nil or has no parent.
    func builtinParent(_ args: [ParsedExpr]) throws -> ProgramValue {
        let node = try evaluateGedcomNodeOpt(args[0], errMsg: "parent: arg must be a node")
        if let node = node, let par = node.dad {
            return .gnode(par)
        }
        return .null
    }
}
