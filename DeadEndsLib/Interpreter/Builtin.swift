//
//  Builtin.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 11 April 2026.
//  Last changed on 29 June 2026.
//

import Foundation

extension Program {

    /// Structure that holds a builtin function.
    struct Builtin {
        
        let min: Int
        let max: Int
        let function: @MainActor ([ParsedExpr]) async throws -> ProgramValue
    }

    /// Build the dictionary of built-in functions.
    func setupBuiltins() {
        
        builtins = [
            "d":    Builtin(min: 1, max: 1) { try await self.bltinD($0)},
            "nl":   Builtin(min: 0, max: 0) { try self.bltinNl($0)},
            "set":  Builtin(min: 2, max: 2) { try await self.bltinSet($0)},
            "ord":  Builtin(min: 1, max: 1) { try await self.bltinOrd($0)},
            "card":  Builtin(min: 1, max: 1) { try await self.bltinCard($0) },
            "roman": Builtin(min: 1, max: 1) { try await self.bltinRoman($0) },
            "null": Builtin(min: 0, max: 0) { try await self.bltinNull($0) },

            // Arithmetic operators.
            "add":  Builtin(min: 2, max: 2) { try await self.bltinAdd($0)},
            "sub":  Builtin(min: 2, max: 2) { try await self.bltinSub($0)},
            "mul":  Builtin(min: 2, max: 2) { try await self.bltinMul($0)},
            "div":  Builtin(min: 2, max: 2) { try await self.bltinDiv($0)},
            "mod":  Builtin(min: 2, max: 2) { try await self.bltinMod($0)},
            "neg":  Builtin(min: 1, max: 1) { try await self.bltinNeg($0)},

            // Increment and decrement operators.
            "incr": Builtin(min: 1, max: 1) { try self.bltinIncr($0)},
            "decr": Builtin(min: 1, max: 1) { try self.bltinDecr($0)},

            // Comparison operators.
            "eq": Builtin(min: 2, max: 2) { try await self.bltinEq($0)},
            "ne": Builtin(min: 2, max: 2) { try await self.bltinNe($0)},
            "lt": Builtin(min: 2, max: 2) { try await self.bltinLt($0)},
            "le": Builtin(min: 2, max: 2) { try await self.bltinLe($0)},
            "gt": Builtin(min: 2, max: 2) { try await self.bltinGt($0)},
            "ge": Builtin(min: 2, max: 2) { try await self.bltinGe($0)},

            // Logical operators.
            "and": Builtin(min: 1, max: 32) { try await self.bltinAnd($0)},
            "or":  Builtin(min: 1, max: 32) { try await self.bltinOr($0)},
            "not": Builtin(min: 1, max: 1) { try await self.bltinNot($0)},

            // Gedcom node properties and operations.
            "key":  Builtin(min: 1, max: 1) { try await self.bltinKey($0)},
            "tag":  Builtin(min: 1, max: 1) { try await self.bltinTag($0)},
            "val":  Builtin(min: 1, max: 1) { try await self.bltinVal($0)},
            "lev":  Builtin(min: 1, max: 1) { try await self.bltinLev($0)},
            "kid":  Builtin(min: 1, max: 1) { try await self.bltinKid($0)},
            "sib":  Builtin(min: 1, max: 1) { try await self.bltinSib($0)},
            "kids": Builtin(min: 1, max: 1) { try await self.bltinKids($0)},
            "sibs": Builtin(min: 1, max: 1) { try await self.bltinSibs($0)},
            "dad":  Builtin(min: 1, max: 1) { try await self.bltinDad($0)},
            "root": Builtin(min: 1, max: 1) { try await self.bltinRoot($0)},
            "kidwithtag": Builtin(min: 2, max: 2) { try await self.bltinKidWithTag($0)},
            "kidswithtag": Builtin(min: 2, max: 2) { try await self.bltinKidsWithTag($0)},

            // Person operations.
            "person":   Builtin(min: 1, max: 1) { try await self.bltinPerson($0)},
            "name":     Builtin(min: 1, max: 1) { try await self.bltinName($0)},
            "fullname": Builtin(min: 4, max: 4) { try await self.bltinFullName($0)},
            "givens":   Builtin(min: 1, max: 1) { try await self.bltinGivens($0)},
            "surname":  Builtin(min: 1, max: 1) { try await self.bltinSurname($0)},
            "birth":    Builtin(min: 1, max: 1) { try await self.bltinBirth($0)},
            "death":    Builtin(min: 1, max: 1) { try await self.bltinDeath($0)},
            "father":   Builtin(min: 1, max: 1) { try await self.bltinFather($0)},
            "mother":   Builtin(min: 1, max: 1) { try await self.bltinMother($0)},
            "families": Builtin(min: 1, max: 1) { try await self.bltinFamilyList($0)},
            "allpersons":  Builtin(min: 0, max: 0) { try self.bltinAllPersons($0)},
            "male":     Builtin(min: 1, max: 1) { try await self.bltinMale($0)},
            "female":   Builtin(min: 1, max: 1) { try await self.bltinFemale($0)},

            "allfamilies": Builtin(min: 0, max: 0) { try self.bltinAllFamilies($0)},

            /// Generic operations on persons and families.
            "husband":  Builtin(min: 1, max: 1) { try await self.bltinHusband($0)},
            "wife":     Builtin(min: 1, max: 1) { try await self.bltinWife($0)},
            "husbands": Builtin(min: 1, max: 1) { try await self.bltinHusbands($0)},
            "wives":    Builtin(min: 1, max: 1) { try await self.bltinWives($0)},
            "children": Builtin(min: 1, max: 1) { try await self.bltinChildren($0)},
            "spouses":  Builtin(min: 1, max: 1) { try await self.bltinSpouses($0)},
            "parents":  Builtin(min: 1, max: 1) { try await self.bltinParents($0)},
            "siblings": Builtin(min: 1, max: 1) { try await self.bltinSiblings($0)},

            // Event operations.
            "date":  Builtin(min: 1, max: 1) { try await self.bltinDate($0)},
            "place": Builtin(min: 1, max: 1) { try await self.bltinPlace($0)},

            // Generic operations on lists, tables and person sets.
            "empty":  Builtin(min: 1, max: 1) { try await self.bltinEmpty($0)},
            "length": Builtin(min: 1, max: 1) { try await self.bltinLength($0)},
            "clear":  Builtin(min: 1, max: 1) { try self.bltinClear($0)},
            "subscript": Builtin(min: 2, max: 2) { try await self.bltinSubscript($0)},

            "traverse":  Builtin(min: 1, max: 1) { try await self.bltinNodes($0)},

            // List operations; the length and empty builtins are generic.
            "list":    Builtin(min: 0, max: 0) { try self.bltinList($0)},
            "append":  Builtin(min: 2, max: 2) { try await self.bltinAppend($0)},
            "prepend": Builtin(min: 2, max: 2) { try await self.bltinPrepend($0)},
            "push":    Builtin(min: 2, max: 2) { try await self.bltinAppend($0)},
            "pop":     Builtin(min: 1, max: 1) { try await self.bltinRemoveLast($0)},
            "enqueue": Builtin(min: 2, max: 2) { try await self.bltinAppend($0)},
            "dequeue": Builtin(min: 1, max: 1) { try await self.bltinRemoveFirst($0)},

            // Tuple shorthands for lists.
            "pair":   Builtin(min: 2, max: 2) { try await self.bltinPair($0)},
            "first":    Builtin(min: 1, max: 1) { try await self.bltinFirst($0)},
            "second":    Builtin(min: 1, max: 1) { try await self.bltinSecond($0)},

            // Table operations.
            "table":  Builtin(min: 0, max: 0) { try self.bltinTable($0)},
            "insert": Builtin(min: 3, max: 3) { try await self.bltinInsert($0)},
            "lookup": Builtin(min: 2, max: 2) { try await self.bltinLookup($0)},

            // Person set operations.
            "personset":     Builtin(min: 0, max: 0) { try self.bltinPersonSet($0)},
            "addtoset" :     Builtin(min: 2, max: 3) { try await self.bltinAddToSet($0)},
            "removefromset": Builtin(min: 2, max: 2) { try await self.bltinDeleteFromSet($0)},
            "union"    :     Builtin(min: 2, max: 2) { try await self.bltinUnion($0)},
            "intersect":     Builtin(min: 2, max: 2) { try await self.bltinIntersect($0)},
            "difference":    Builtin(min: 2, max: 2) { try await self.bltinDifference($0)},
            "parentset" :    Builtin(min: 1, max: 1) { try await self.bltinParentSet($0)},
            "childset" :     Builtin(min: 1, max: 1) { try await self.bltinChildSet($0)},
            "spouseset":     Builtin(min: 1, max: 1) { try await self.bltinSpouseSet($0)},
            "siblingset":    Builtin(min: 1, max: 1) { try await self.bltinSiblingSet($0)},
            "ancestorset":   Builtin(min: 1, max: 1) { try await self.bltinAncestorSet($0)},
            "descendentset": Builtin(min: 1, max: 1) { try await self.bltinDescendentSet($0)},
            "namesort":      Builtin(min: 1, max: 1) { try await self.bltinNameSort($0)},
            "keysort":       Builtin(min: 1, max: 1) { try await self.bltinKeySort($0)},

            // String operations.
            "strcmp": Builtin(min: 2, max: 2) { try await self.bltinStrcmp($0)},

            // Meta operations.
            "showframe": Builtin(min: 0, max: 0) { try self.bltinShowFrame($0)},
            "showstack": Builtin(min: 0, max: 0) { try self.bltinShowStack($0)},
            "valueof":   Builtin(min: 1, max: 1) { try await self.bltinValueOf($0)},

            // User interface.
            "getperson": Builtin(min: 1, max: 1) { try await self.bltinGetPerson($0)},
            "getinteger": Builtin(min: 1, max: 1) { try await self.bltinGetInteger($0)},
            "getstring": Builtin(min: 1, max: 1) { try await self.bltinGetString($0)},

            // Extract built-ins.
            "extractname": Builtin(min: 4, max: 4) { try await self.bltinExtractName($0)},
        ]
    }
}

extension Program {
    
    /// Returns an integer as a string.
    func bltinD(_ args: [ParsedExpr]) async throws -> ProgramValue {
        let value = try await self.evaluate(args[0])
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
    func bltinSet(_ args: [ParsedExpr]) async throws -> ProgramValue {
        guard case let .identifier(name) = args[0].kind else {
            throw RuntimeError("set() expects a variable as its first argument", line: args[0].line)
        }
        let value = try await evaluate(args[1])
        assignToSymbol(name, value: value)
        return .null  // Side effect only.
    }

    /// Return a .null program value.
    func bltinNull(_ args: [ParsedExpr]) async throws -> ProgramValue {
        .null
    }
}
