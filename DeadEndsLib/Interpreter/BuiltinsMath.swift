//
//  BuiltinsMath.swift
//  This file has the builtin functions for add, sub, mul, div, mod, neg, eq, ne, lt, le, gt, ge,
//    and, or, not, incr, decr.
//  TODO: SHOULD THERE BE AN EXP OPERATION.
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 12 April 2025.
//  Last changed on 26 April 2025.
//

import Foundation

// Program extension for the arithmetics.
extension Program {

    // builtinAdd is the builtin addition function.
    func builtinAdd(_ args: [ProgramNode]) throws -> ProgramValue {
        let arg1 = try self.evaluate(args[0])
        let arg2 = try self.evaluate(args[1])
        let result = ProgramValue.addPValues(arg1, arg2)
        if result == .null {
            throw RuntimeError.typeMismatch("add requires two integers, two floats, or two strings")
        }
        return result
    }

    // builtinSub is the builtin subtraction function.
    func builtinSub(_ args: [ProgramNode]) throws -> ProgramValue {
        let arg1 = try self.evaluate(args[0])
        let arg2 = try self.evaluate(args[1])
        let result = ProgramValue.subPValues(arg1, arg2)
        guard result != .null else {
            throw RuntimeError.typeMismatch("sub requires two integers or two floats")
        }
        return result
    }

    // builtinMul is the builtin multiplication function.
    func builtinMul(_ args: [ProgramNode]) throws -> ProgramValue {
        let arg1 = try self.evaluate(args[0])
        let arg2 = try self.evaluate(args[1])
        let result = ProgramValue.mulPValues(arg1, arg2)
        guard result != .null else {
            throw RuntimeError.typeMismatch("mul requires two integers or two floats")
        }
        return result
    }

    // builtinDiv is the builtin division function.
    func builtinDiv(_ args: [ProgramNode]) throws -> ProgramValue {
        let arg2 = try self.evaluate(args[1])
        if arg2 == .integer(0) || arg2 == .double(0.0) { // Check for zero divisor.
            throw RuntimeError.runtimeError("division by zero is not allowed")
        }
        let arg1 = try self.evaluate(args[0])
        let result = ProgramValue.divPValues(arg1, arg2)
        guard result != .null else {
            throw RuntimeError.typeMismatch("div requires two integers or two floats")
        }
        return result
    }

    // builtinMod is the builtin modulus function.
    func builtinMod(_ args: [ProgramNode]) throws -> ProgramValue {
        let arg1 = try self.evaluate(args[0])
        let arg2 = try self.evaluate(args[1])
        guard case let .integer(left) = arg1, case let .integer(right) = arg2 else { // Only integers.
            throw RuntimeError.typeMismatch("mod requires two integer arguments")
        }
        if right == 0 { // Check for zero.
            throw RuntimeError.runtimeError("modulo by zero is not allowed")
        }
        return .integer(left % right)
    }

    // builtinNeg is the builtin negation function.
    func builtinNeg(_ args: [ProgramNode]) throws -> ProgramValue {
        // Evaluate the argument and check that it's numeric.
        let arg = try self.evaluate(args[0])
        if !ProgramValue.isNumeric(arg) {
            throw RuntimeError.typeMismatch("neg requires a numeric argument")
        }
        let result = ProgramValue.negPValue(arg)
        if result == .null {
            throw RuntimeError.typeMismatch("neg requires a numeric argument")
        }
        return result
    }
}

// Program extension for the comparison builtins.
extension Program {

    func builtinEq(_ args: [ProgramNode]) throws -> ProgramValue {
        let a = try evaluate(args[0])
        let b = try evaluate(args[1])
        return .boolean(a == b)
    }

    func builtinNe(_ args: [ProgramNode]) throws -> ProgramValue {
        let a = try evaluate(args[0])
        let b = try evaluate(args[1])
        return .boolean(a != b)
    }

    func builtinLt(_ args: [ProgramNode]) throws -> ProgramValue {
        let a = try evaluate(args[0])
        let b = try evaluate(args[1])
        return ProgramValue.compare(a, b, using: <)
    }

    func builtinLe(_ args: [ProgramNode]) throws -> ProgramValue {
        let a = try evaluate(args[0])
        let b = try evaluate(args[1])
        return ProgramValue.compare(a, b, using: <=)
    }

    func builtinGt(_ args: [ProgramNode]) throws -> ProgramValue {
        let a = try evaluate(args[0])
        let b = try evaluate(args[1])
        return ProgramValue.compare(a, b, using: >)
    }

    func builtinGe(_ args: [ProgramNode]) throws -> ProgramValue {
        let a = try evaluate(args[0])
        let b = try evaluate(args[1])
        return ProgramValue.compare(a, b, using: >=)
    }
}

// Program extension for increment and decrement builtins.
extension Program {

    // builtinIncr increments the value of an integer variable.
    func builtinIncr(_ args: [ProgramNode]) throws -> ProgramValue {
        // Argument must be an identifier.
        guard case let .identifier(name) = args[0].kind else {
            throw RuntimeError.typeError("incr() expects a variable name")
        }
        // The identifer must be in a symbol table and have an integer value.
        guard let current = lookupSymbol(name) else {
            throw RuntimeError.undefinedSymbol("incr(): variable '\(name)' is not defined")
        }
        guard case let .integer(i) = current else {
            throw RuntimeError.typeMismatch("incr() requires an integer variable")
        }
        // Store back the incremented value.
        let newVal = ProgramValue.integer(i + 1)
        assignToSymbol(name, value: newVal)
        return newVal
    }

    // builtinDecr decrements the value of an integer variable.
    func builtinDecr(_ args: [ProgramNode]) throws -> ProgramValue {
        // Argument must be an identifier.
        guard case let .identifier(name) = args[0].kind else {
            throw RuntimeError.typeError("decr() expects a variable name")
        }
        // The identifer must be in a symbol table and have an integer value.
        guard let current = lookupSymbol(name) else {
            throw RuntimeError.undefinedSymbol("decr(): variable '\(name)' is not defined")
        }
        guard case let .integer(i) = current else {
            throw RuntimeError.typeMismatch("decr() requires an integer variable")
        }
        // Store back the decremented value.
        let newVal = ProgramValue.integer(i - 1)
        assignToSymbol(name, value: newVal)
        return newVal
    }
}

// Program extension for the logical builtins.
extension Program {

    // builtinAnd implements the logical and operation; takes any number of arguments.
    func builtinAnd(_ args: [ProgramNode]) throws -> ProgramValue {
        for arg in args {
            if !(try evaluate(arg).toBool()) {
                return .falseProgramValue
            }
        }
        return .trueProgramValue
    }

    // builtinOr implements the logical or operation; takes any number of arguments.
    func builtinOr(_ args: [ProgramNode]) throws -> ProgramValue {
        for arg in args {
            if try evaluate(arg).toBool() {
                return .trueProgramValue
            }
        }
        return .falseProgramValue
    }

    // builtinNot implemements the logical not operation.
    func builtinNot(_ args: [ProgramNode]) throws -> ProgramValue {
        return try evaluate(args[0]).toBool() ? .falseProgramValue : .trueProgramValue
    }
}
