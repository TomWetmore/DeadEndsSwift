//
//  BuiltIn.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore 18 March 2025.
//  Last changed on 27 April 2025.
//

import Foundation

extension Program {

    struct Builtin {
        let minArgs: Int
        let maxArgs: Int
        let function: ([ProgramNode]) throws -> ProgramValue
    }

    func setupBuiltins() {
        builtins = [
            "d":    Builtin(minArgs: 1, maxArgs: 1) { try self.builtinD($0) },
            "nl":   Builtin(minArgs: 0, maxArgs: 0) { try self.builtinNl($0) },
            "set":  Builtin(minArgs: 2, maxArgs: 2) { try self.builtinSet($0) },

            // Arithmetic operatotrs.
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

            // Set theoretic operators.
            "and": Builtin(minArgs: 1, maxArgs: 32) { try self.builtinAnd($0) },
            "or":  Builtin(minArgs: 1, maxArgs: 32) { try self.builtinOr($0) },
            "not": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinNot($0) },

            // Person operations.
            "indi": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinIndi($0) },
            "name": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinName($0) },
            //"givens": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinGivens($0) },
            //"surname": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinSurname($0) },
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
        ]
    }
}

extension Program {

    // builtinD returns an integer as a string.
    func builtinD(_ args: [ProgramNode]) throws -> ProgramValue {
        let value = try self.evaluate(args[0])
        guard case let .integer(integer) = value else {
            throw RuntimeError.typeMismatch("d() requires an integer argument")
        }
        return .string(String(integer))
    }

    // builtinNl returns a newline character.
    func builtinNl(_ args: [ProgramNode]) throws -> ProgramValue {
        return .string("\n")
    }
}

// MARK: Support Routines

// normalizeRecordKey allows keys without @-signs and with lower case letters.
func normalizeRecordKey(_ userKey: String) -> String {
    let trimmed = userKey.trimmingCharacters(in: CharacterSet(charactersIn: "@"))
    return "@\(trimmed.uppercased())@"
}

// Program extension for some misc builtins.
extension Program {

    // builtinSet is the assignment statement of the scripting language.
    func builtinSet(_ args: [ProgramNode]) throws -> ProgramValue {
        guard case let .identifier(name) = args[0].kind else { // Get the identifier.
            throw RuntimeError.typeError("set() expects a variable as its first argument")
        }
        let value = try evaluate(args[1]) // Get the value.
        assignToSymbol(name, value: value) // Assign the value to the variable.
        return .null
    }
}
