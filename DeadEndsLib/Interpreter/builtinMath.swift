//
//  builtinMath.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 11 April 2026.
//  Last changed 11 April 2026.
//
//  This file has the builtin functions for add, sub, mul, div, mod, neg,
//  eq, ne, lt, le, gt, ge, and, or, not, incr, decr.
//  TODO: SHOULD THERE BE AN EXP OPERATION.

import Foundation

// Arithmetic builtins.
extension Program {

    /// Addition function.
    func builtinAdd(_ args: [ParsedExpr]) throws -> ProgramValue {
        let arg1 = try self.evaluate(args[0])
        let arg2 = try self.evaluate(args[1])
        let result = ProgramValue.addPValues(arg1, arg2)
        if result == .null {
            throw RuntimeError.typeMismatch("add requires two integers, two floats, or two strings")
        }
        return result
    }

    /// Subtraction function.
    func builtinSub(_ args: [ParsedExpr]) throws -> ProgramValue {
        let arg1 = try self.evaluate(args[0])
        let arg2 = try self.evaluate(args[1])
        let result = ProgramValue.subPValues(arg1, arg2)
        guard result != .null else {
            throw RuntimeError.typeMismatch("sub requires two integers or two floats")
        }
        return result
    }

    /// Multiplication function.
    func builtinMul(_ args: [ParsedExpr]) throws -> ProgramValue {
        let arg1 = try self.evaluate(args[0])
        let arg2 = try self.evaluate(args[1])
        let result = ProgramValue.mulPValues(arg1, arg2)
        guard result != .null else {
            throw RuntimeError.typeMismatch("mul requires two integers or two floats")
        }
        return result
    }

    /// Division function.
    func builtinDiv(_ args: [ParsedExpr]) throws -> ProgramValue {
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

    /// Modulus function.
    func builtinMod(_ args: [ParsedExpr]) throws -> ProgramValue {
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

    /// Negation function.
    func builtinNeg(_ args: [ParsedExpr]) throws -> ProgramValue {
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

/// Comparison builtins.
extension Program {

    /// Equal predicate.
    func builtinEq(_ args: [ParsedExpr]) throws -> ProgramValue {
        let a = try evaluate(args[0])
        let b = try evaluate(args[1])
        return .boolean(a == b)
    }

    /// Not equal predicate.
    func builtinNe(_ args: [ParsedExpr]) throws -> ProgramValue {
        let a = try evaluate(args[0])
        let b = try evaluate(args[1])
        return .boolean(a != b)
    }

    /// Less than predicate.
    func builtinLt(_ args: [ParsedExpr]) throws -> ProgramValue {
        let a = try evaluate(args[0])
        let b = try evaluate(args[1])
        return ProgramValue.compare(a, b, using: <)
    }

    /// Less than or equal predicate.
    func builtinLe(_ args: [ParsedExpr]) throws -> ProgramValue {
        let a = try evaluate(args[0])
        let b = try evaluate(args[1])
        return ProgramValue.compare(a, b, using: <=)
    }

    /// Greater than predicate.
    func builtinGt(_ args: [ParsedExpr]) throws -> ProgramValue {
        let a = try evaluate(args[0])
        let b = try evaluate(args[1])
        return ProgramValue.compare(a, b, using: >)
    }

    /// Greator than or equal predicate.
    func builtinGe(_ args: [ParsedExpr]) throws -> ProgramValue {
        let a = try evaluate(args[0])
        let b = try evaluate(args[1])
        return ProgramValue.compare(a, b, using: >=)
    }
}

// Increment and decrement builtins.
extension Program {

    /// Increment function.
    func builtinIncr(_ args: [ParsedExpr]) throws -> ProgramValue {
        // Argument must be an identifier.
        guard case let .identifier(name) = args[0] else {
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

    // Decrement function.
    func builtinDecr(_ args: [ParsedExpr]) throws -> ProgramValue {
        // Argument must be an identifier.
        guard case let .identifier(name) = args[0] else {
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

// Logical builtins.
extension Program {

    /// Logical and operation.
    func builtinAnd(_ args: [ParsedExpr]) throws -> ProgramValue {
        for arg in args {
            if !(try evaluate(arg).toBool()) {
                return .falseProgramValue
            }
        }
        return .trueProgramValue
    }

    /// Logical or operation.
    func builtinOr(_ args: [ParsedExpr]) throws -> ProgramValue {
        for arg in args {
            if try evaluate(arg).toBool() {
                return .trueProgramValue
            }
        }
        return .falseProgramValue
    }

    /// Logical not operation.
    func builtinNot(_ args: [ParsedExpr]) throws -> ProgramValue {
        return try evaluate(args[0]).toBool() ? .falseProgramValue : .trueProgramValue
    }
}

