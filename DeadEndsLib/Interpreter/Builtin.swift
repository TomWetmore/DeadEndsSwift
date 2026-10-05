//
//  Builtin.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 11 April 2026.
//  Last changed on 4 October 2026.
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
            // Miscellaneous operations.
            "d": Builtin(min: 1, max: 1) { try await self.bltinD($0)},
            "nl": Builtin(min: 0, max: 0) { try self.bltinNl($0)},
            "qt": Builtin(min: 0, max: 0) { try self.bltinQuote($0)},
            "set": Builtin(min: 2, max: 2) { try await self.bltinSet($0)},
            "null": Builtin(min: 0, max: 0) { try await self.bltinNull($0)},
            "true": Builtin(min: 0, max: 0) { try await self.bltinTrue($0)},
            "false": Builtin(min: 0, max: 0) { try await self.bltinFalse($0)},

            // String operations.
            "upper": Builtin(min: 1, max: 1) { try await self.bltinUpper($0)},
            "lower": Builtin(min: 1, max: 1) { try await self.bltinLower($0)},
            "capitalize": Builtin(min: 1, max: 1) { try await self.bltinCapitalize($0)},
            "words": Builtin(min: 1, max: 1) { try await self.bltinWords($0)},
            "tokens": Builtin(min: 1, max: 1) { try await self.bltinTokens($0)},
            "strcmp": Builtin(min: 2, max: 2) { try await self.bltinStrcmp($0)},
            "ord": Builtin(min: 1, max: 1) { try await self.bltinOrd($0)},
            "card": Builtin(min: 1, max: 1) { try await self.bltinCard($0)},
            "roman": Builtin(min: 1, max: 1) { try await self.bltinRoman($0)},
            // "trim": Builtin(min: 1, max: 1) { try await self.bltinTrim($0)},
            // "rjustify": Builtin(min: 1, max: 1) { try await self.bltinRJustify($0)},

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
            "person": Builtin(min: 1, max: 1) { try await self.bltinPerson($0)},
            "name": Builtin(min: 1, max: 1) { try await self.bltinName($0)},
            "sex": Builtin(min: 1, max: 1) { try await self.bltinSex($0)},
            "fullname": Builtin(min: 4, max: 4) { try await self.bltinFullName($0)},
            "givens": Builtin(min: 1, max: 1) { try await self.bltinGivens($0)},
            "surname": Builtin(min: 1, max: 1) { try await self.bltinSurname($0)},
            "trimname": Builtin(min: 2, max: 2) { try await self.bltinTrimName($0)},
            "title": Builtin(min: 1, max: 1) { try await self.bltinTitle($0)},
            "birth": Builtin(min: 1, max: 1) { try await self.bltinBirth($0)},
            "death": Builtin(min: 1, max: 1) { try await self.bltinDeath($0)},
            "baptism": Builtin(min: 1, max: 1) { try await self.bltinBaptism($0)},
            "burial": Builtin(min: 1, max: 1) { try await self.bltinBurial($0)},
            "nextsib": Builtin(min: 1, max: 1) { try await self.bltinNextSib($0)},
            "prevsib": Builtin(min: 1, max: 1) { try await self.bltinPrevSib($0)},
            "families": Builtin(min: 1, max: 1) { try await self.bltinFamilyList($0)},
            "male":  Builtin(min: 1, max: 1) { try await self.bltinMale($0)},
            "female": Builtin(min: 1, max: 1) { try await self.bltinFemale($0)},
            "allpersons":  Builtin(min: 0, max: 0) { try self.bltinAllPersons($0)},

            // Family operations.
            "family": Builtin(min: 1, max: 1) { try await self.bltinFamily($0)},
            "marriage": Builtin(min: 1, max: 1) { try await self.bltinMarriage($0)},
            "divorce": Builtin(min: 1, max: 1) { try await self.bltinDivorce($0)},
            "allfamilies": Builtin(min: 0, max: 0) { try self.bltinAllFamilies($0)},

            /// Relationship operations on Persons, Families, and PersonSets.
            "children": Builtin(min: 1, max: 1) { try await self.bltinChildren($0)},
            "parents": Builtin(min: 1, max: 1) { try await self.bltinParents($0)},
            "fathers": Builtin(min: 1, max: 1) { try await self.bltinFathers($0)},
            "mothers": Builtin(min: 1, max: 1) { try await self.bltinMothers($0)},
            "father": Builtin(min: 1, max: 1) { try await self.bltinFather($0)},
            "mother": Builtin(min: 1, max: 1) { try await self.bltinMother($0)},
            "spouses": Builtin(min: 1, max: 1) { try await self.bltinSpouses($0)},
            "husbands": Builtin(min: 1, max: 1) { try await self.bltinHusbands($0)},
            "wives": Builtin(min: 1, max: 1) { try await self.bltinWives($0)},
            "husband": Builtin(min: 1, max: 1) { try await self.bltinHusband($0)},
            "wife": Builtin(min: 1, max: 1) { try await self.bltinWife($0)},
            "siblings": Builtin(min: 1, max: 1) { try await self.bltinSiblings($0)},
            "ancestors": Builtin(min: 1, max: 1) { try await self.bltinAncestors($0)},
            "descendants": Builtin(min: 1, max: 1) { try await self.bltinDescendants($0)},
            "sons": Builtin(min: 1, max: 1) { try await self.bltinSons($0)},
            "daughters": Builtin(min: 1, max: 1) { try await self.bltinDaughters($0)},
            "brothers": Builtin(min: 1, max: 1) { try await self.bltinBrothers($0)},
            "sisters": Builtin(min: 1, max: 1) { try await self.bltinSisters($0)},
            "nchildren": Builtin(min: 1, max: 1) { try await self.bltinNChildren($0)},
            "nspouses": Builtin(min: 1, max: 1) { try await self.bltinNSpouses($0)},

            // Event operations.
            "date":  Builtin(min: 1, max: 1) { try await self.bltinDate($0)},
            "place": Builtin(min: 1, max: 1) { try await self.bltinPlace($0)},

            // Generic operations on lists, tables, and personsets.
            "empty": Builtin(min: 1, max: 1) { try await self.bltinEmpty($0)},
            "length": Builtin(min: 1, max: 1) { try await self.bltinLength($0)},
            "clear": Builtin(min: 1, max: 1) { try await self.bltinClear($0)},
            "subscript": Builtin(min: 2, max: 2) { try await self.bltinSubscript($0)},
            "traverse": Builtin(min: 1, max: 1) { try await self.bltinNodes($0)},

            // List operations.
            "list": Builtin(min: 0, max: 0) { try self.bltinList($0)},
            "append": Builtin(min: 2, max: 2) { try await self.bltinAppend($0)},
            "prepend": Builtin(min: 2, max: 2) { try await self.bltinPrepend($0)},
            "push": Builtin(min: 2, max: 2) { try await self.bltinAppend($0)},
            "pop": Builtin(min: 1, max: 1) { try await self.bltinRemoveLast($0)},
            "enqueue": Builtin(min: 2, max: 2) { try await self.bltinAppend($0)},
            "dequeue": Builtin(min: 1, max: 1) { try await self.bltinRemoveFirst($0)},
            "removefirst": Builtin(min: 1, max: 1) { try await self.bltinRemoveFirst($0)},
            "removelast": Builtin(min: 1, max: 1) { try await self.bltinRemoveLast($0)},
            "copy": Builtin(min: 1, max: 1) { try await self.bltinCopy($0)},

            // Tuple operations.
            "pair":  Builtin(min: 2, max: 2) { try await self.bltinPair($0)},
            "first": Builtin(min: 1, max: 1) { try await self.bltinFirst($0)},
            "second": Builtin(min: 1, max: 1) { try await self.bltinSecond($0)},

            // Table operations.
            "table":  Builtin(min: 0, max: 0) { try self.bltinTable($0)},
            "insert": Builtin(min: 3, max: 3) { try await self.bltinInsert($0)},
            "lookup": Builtin(min: 2, max: 2) { try await self.bltinLookup($0)},
            "contains": Builtin(min: 2, max: 2) { try await self.bltinContains($0)},

            // Person set operations.
            "personset": Builtin(min: 0, max: 0) { try self.bltinPersonSet($0)},
            "addtoset" : Builtin(min: 2, max: 3) { try await self.bltinAddToSet($0)},
            "removefromset": Builtin(min: 2, max: 2) { try await self.bltinDeleteFromSet($0)},
            "union": Builtin(min: 2, max: 2) { try await self.bltinUnion($0)},
            "intersect": Builtin(min: 2, max: 2) { try await self.bltinIntersect($0)},
            "difference": Builtin(min: 2, max: 2) { try await self.bltinDifference($0)},
            "namesort": Builtin(min: 1, max: 1) { try await self.bltinNameSort($0)},
            "keysort": Builtin(min: 1, max: 1) { try await self.bltinKeySort($0)},
            "gengedcom": Builtin(min: 1, max: 1) { try await self.bltinGenGedcom($0)},

            // Debugging operations.
            "showframe": Builtin(min: 0, max: 0) { try self.bltinShowFrame($0)},
            "showstack": Builtin(min: 0, max: 0) { try self.bltinShowStack($0)},
            "valueof": Builtin(min: 1, max: 1) { try await self.bltinValueOf($0)},

            // User interface.
            "getperson": Builtin(min: 1, max: 1) { try await self.bltinGetPerson($0)},
            "getinteger": Builtin(min: 1, max: 1) { try await self.bltinGetInteger($0)},
            "getstring": Builtin(min: 1, max: 1) { try await self.bltinGetString($0)},

            // Extract built-ins.
            "extractname": Builtin(min: 1, max: 1) { try await self.bltinExtractName($0)},
            "extractplace": Builtin(min: 1, max: 1) { try await self.bltinExtractPlace($0)},
        ]
    }
}

extension Program {
    
    /// Return an integer as a string.
    /// d(int) -> string|null

    func bltinD(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let value = try await self.evaluate(args[0])
        if value == .null { return .null }  // Allow null propagation.
        guard case let .integer(integer) = value else {
            return .null
        }
        return .string(String(integer))
    }
    
    /// Return an ascii newline character as a string.
    /// nl() -> string
    ///
    func bltinNl(_ args: [ParsedExpr]) throws -> ProgramValue {
        
        return .string("\n")
    }

    /// Return an ascii double quote character as a string.
    /// qt() -> string
    ///
    func bltinQuote(_ args: [ParsedExpr]) throws -> ProgramValue {
        return .string("\"")
    }

    /// Assignment 'statement'.
    /// set(ident, any) -> null
    ///
    func bltinSet(_ args: [ParsedExpr]) async throws -> ProgramValue {

        guard case let .identifier(name) = args[0].kind else {
            throw RuntimeError("set() expects a variable as its first argument",
                               line: args[0].line)
        }
        let value = try await evaluate(args[1])
        assignToSymbol(name, value: value)
        return .null  // Side effect only.
    }

    /// Return a .null program value.
    /// null() -> null
    ///
    func bltinNull(_ args: [ParsedExpr]) async throws -> ProgramValue {
        .null
    }

    /// Return a true program value.
    /// true() -> bool
    ///
    func bltinTrue(_ args: [ParsedExpr]) async throws -> ProgramValue {
        return .boolean(true)
    }

    /// Return a false program value.
    /// false() -> bool
    ///
    func bltinFalse(_ args: [ParsedExpr]) async throws -> ProgramValue {
        return .boolean(false)
    }
}

public final class Pair {
    
    let first: ProgramValue
    let second: ProgramValue

    init(_ first: ProgramValue, _ second: ProgramValue) {
        self.first = first
        self.second = second
    }
}

enum BuiltinInfo {
    
    static let names: Set<String> = [
        // Miscellaneous.
       "d", "nl", "qt", "set",  "null", "true", "false",

       // Strings.
       "upper", "lower", "capitalize", "words", "tokens", "strcmp", "ord", "card", "roman",
       // "trim", "rjustify",
       
       // Arithmetic.
       "add", "sub", "mul", "div", "mod", "neg",

       // Increment and decrement.
       "incr", "decr",

       // Comparison.
       "eq", "ne", "lt", "le", "gt", "ge",

       // Logical.
       "and", "or", "not",

       // Gedcom nodes.
       "key", "tag", "val", "lev", "kid", "sib", "kids", "sibs", "dad", "root",
       "kidwithtag", "kidswithtag",

       // Persons.
       "person", "name", "sex", "fullname", "givens", "surname", "trimname", "title",
       "birth", "death", "baptism", "burial", "nextsib", "prevsib", "families",
       "male", "female","allpersons",

       // Families.
       "family", "marriage", "divorce", "allfamilies",

       /// Relationship operations on Persons, Families, and PersonSets.
       "children", "parents", "fathers", "mothers", "father", "mother", "spouses",
       "husbands", "wives", "husband", "wife", "siblings", "ancestors",
       "descendants", "sons", "daughters", "brothers", "sisters", "nchildren",
       "nspouses",

       // Events.
       "date", "place",

       // Generics.
       "empty", "length", "clear", "subscript", "traverse",

       // Lists.
       "list", "append", "prepend", "push", "pop", "enqueue", "dequeue", "removefirst",
       "removelast", "copy",

       // Tuples.
       "pair", "first", "second",

       // Tables.
       "table", "insert", "lookup", "contains",

       // Personsets.
       "personset", "addtoset" , "removefromset", "union", "intersect", "difference",
       "namesort", "keysort", "gengedcom",

       // Metas.
       "showframe", "showstack", "valueof",

       // User interface.
       "getperson", "getinteger", "getstring",
       
       // Extracts.
       "extractname", "extractplace",
    ]
}
