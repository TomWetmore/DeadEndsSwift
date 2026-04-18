//
//  Builtin.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 11 April 2026.
//  Last changed on 14 April 2026.
//

import Foundation

extension Program {

    /// Structure holding a builtin function. Unlike user functions the
    /// arguments are not evaluated.
    struct Builtin {
        let minArgs: Int
        let maxArgs: Int
        let function: ([ParsedExpr]) throws -> ProgramValue
    }

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

            // Person operations.
            "indi": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinIndi($0) },
            "name": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinName($0) },
            "givens": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinGivens($0) },
            "surname": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinSurname($0) },
            "birth" : Builtin(minArgs: 1, maxArgs: 1) { try self.builtinBirth($0) },
            "death": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinDeath($0) },

            // Event operations.
            "date":  Builtin(minArgs: 1, maxArgs: 1) { try self.builtinDate($0) },
            "place": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinPlace($0) },

            // List operations.
            "append":  Builtin(minArgs: 2, maxArgs: 2) { try self.builtinAppend($0) },
            "prepend": Builtin(minArgs: 2, maxArgs: 2) { try self.builtinPrepend($0) },
            "push":    Builtin(minArgs: 2, maxArgs: 2) { try self.builtinAppend($0) },
            "pop":     Builtin(minArgs: 1, maxArgs: 1) { try self.builtinRemoveFirst($0) },
            "enqueue": Builtin(minArgs: 2, maxArgs: 2) { try self.builtinAppend($0) },
            "dequeue": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinRemoveFirst($0) },

            // Table operations.
            "table": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinTable($0) },
            "insert": Builtin(minArgs: 3, maxArgs: 3) { try self.builtinInsert($0) },
            "lookup": Builtin(minArgs: 2, maxArgs: 2) { try self.builtinLookup($0) },
        ]
    }
}

extension Program {
    
    /// builtinD returns an integer as a string.
    func builtinD(_ args: [ParsedExpr]) throws -> ProgramValue {
        let value = try self.evaluate(args[0])
        guard case let .integer(integer) = value else {
            throw RuntimeError.typeMismatch("d() requires an integer argument")
        }
        return .string(String(integer))
    }
    
    /// Returns a newline character.
    func builtinNl(_ args: [ParsedExpr]) throws -> ProgramValue {
        return .string("\n")
    }
    
    /// Assignment 'statement' of the scripting language; side effect only.
    func builtinSet(_ args: [ParsedExpr]) throws -> ProgramValue {
        guard case let .identifier(name) = args[0] else {
            throw RuntimeError.typeError("set() expects a variable as its first argument")
        }
        let value = try evaluate(args[1])
        assignToSymbol(name, value: value)
        return .null  // Side effect only.
    }
}
