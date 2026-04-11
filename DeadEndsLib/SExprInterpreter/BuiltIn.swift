//
//  BuiltIn.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore 18 March 2025.
//  Last changed on 27 April 2025.
//

//import Foundation
//
//extension Program {
//
//    struct OldBuiltin {
//        let minArgs: Int
//        let maxArgs: Int
//        let function: ([ProgramNode]) throws -> ProgramValue
//    }
//
//    func oldSetupBuiltins() {
//        oldBuiltins = [
//            "d":    OldBuiltin(minArgs: 1, maxArgs: 1) { try self.builtinD($0) },
//            "nl":   OldBuiltin(minArgs: 0, maxArgs: 0) { try self.builtinNl($0) },
//            "set":  OldBuiltin(minArgs: 2, maxArgs: 2) { try self.builtinSet($0) },
//
//            // Arithmetic operatotrs.
//            "add":  OldBuiltin(minArgs: 2, maxArgs: 2) { try self.builtinAdd($0) },
//            "sub":  OldBuiltin(minArgs: 2, maxArgs: 2) { try self.builtinSub($0) },
//            "mul":  OldBuiltin(minArgs: 2, maxArgs: 2) { try self.builtinMul($0) },
//            "div":  OldBuiltin(minArgs: 2, maxArgs: 2) { try self.builtinDiv($0) },
//            "mod":  OldBuiltin(minArgs: 2, maxArgs: 2) { try self.builtinMod($0) },
//            "neg":  OldBuiltin(minArgs: 1, maxArgs: 1) { try self.builtinNeg($0) },
//
//            // Increment and decrement operators.
//            "incr": OldBuiltin(minArgs: 1, maxArgs: 1) { try self.builtinIncr($0) },
//            "decr": OldBuiltin(minArgs: 1, maxArgs: 1) { try self.builtinDecr($0) },
//
//            // Comparison operators.
//            "eq": OldBuiltin(minArgs: 2, maxArgs: 2) { try self.builtinEq($0) },
//            "ne": OldBuiltin(minArgs: 2, maxArgs: 2) { try self.builtinNe($0) },
//            "lt": OldBuiltin(minArgs: 2, maxArgs: 2) { try self.builtinLt($0) },
//            "le": OldBuiltin(minArgs: 2, maxArgs: 2) { try self.builtinLe($0) },
//            "gt": OldBuiltin(minArgs: 2, maxArgs: 2) { try self.builtinGt($0) },
//            "ge": OldBuiltin(minArgs: 2, maxArgs: 2) { try self.builtinGe($0) },
//
//            // Set theoretic operators.
//            "and": OldBuiltin(minArgs: 1, maxArgs: 32) { try self.builtinAnd($0) },
//            "or":  OldBuiltin(minArgs: 1, maxArgs: 32) { try self.builtinOr($0) },
//            "not": OldBuiltin(minArgs: 1, maxArgs: 1) { try self.builtinNot($0) },
//
//            // Person operations.
//            "indi": OldBuiltin(minArgs: 1, maxArgs: 1) { try self.builtinIndi($0) },
//            "name": OldBuiltin(minArgs: 1, maxArgs: 1) { try self.builtinName($0) },
//            //"givens": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinGivens($0) },
//            //"surname": Builtin(minArgs: 1, maxArgs: 1) { try self.builtinSurname($0) },
//            "birth" : OldBuiltin(minArgs: 1, maxArgs: 1) { try self.builtinBirth($0) },
//            "death": OldBuiltin(minArgs: 1, maxArgs: 1) { try self.builtinDeath($0) },
//
//            // Event operations.
//            "date":  OldBuiltin(minArgs: 1, maxArgs: 1) { try self.builtinDate($0) },
//            "place": OldBuiltin(minArgs: 1, maxArgs: 1) { try self.builtinPlace($0) },
//
//            // List operations.
//            "append":  OldBuiltin(minArgs: 2, maxArgs: 2) { try self.builtinAppend($0) },
//            "prepend": OldBuiltin(minArgs: 2, maxArgs: 2) { try self.builtinPrepend($0) },
//            "push":    OldBuiltin(minArgs: 2, maxArgs: 2) { try self.builtinAppend($0) },
//            "pop":     OldBuiltin(minArgs: 1, maxArgs: 1) { try self.builtinRemoveFirst($0) },
//            "enqueue": OldBuiltin(minArgs: 2, maxArgs: 2) { try self.builtinAppend($0) },
//            "dequeue": OldBuiltin(minArgs: 1, maxArgs: 1) { try self.builtinRemoveFirst($0) },
//        ]
//    }
//}
//
//extension Program {
//
//    // builtinD returns an integer as a string.
//    func builtinD(_ args: [ProgramNode]) throws -> ProgramValue {
//        let value = try self.evaluate(args[0])
//        guard case let .integer(integer) = value else {
//            throw RuntimeError.typeMismatch("d() requires an integer argument")
//        }
//        return .string(String(integer))
//    }
//
//    // builtinNl returns a newline character.
//    func builtinNl(_ args: [ProgramNode]) throws -> ProgramValue {
//        return .string("\n")
//    }
//}
//
//// MARK: Support Routines
//
//// normalizeRecordKey allows keys without @-signs and with lower case letters.
//func normalizeRecordKey(_ userKey: String) -> String {
//    let trimmed = userKey.trimmingCharacters(in: CharacterSet(charactersIn: "@"))
//    return "@\(trimmed.uppercased())@"
//}
//
//// Program extension for some misc builtins.
//extension Program {
//
//    // builtinSet is the assignment statement of the scripting language.
//    func builtinSet(_ args: [ProgramNode]) throws -> ProgramValue {
//        guard case let .identifier(name) = args[0].kind else { // Get the identifier.
//            throw RuntimeError.typeError("set() expects a variable as its first argument")
//        }
//        let value = try evaluate(args[1]) // Get the value.
//        assignToSymbol(name, value: value) // Assign the value to the variable.
//        return .null
//    }
//}
