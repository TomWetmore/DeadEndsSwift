//
//  BuiltinMath.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 11 April 2026.
//  Last changed 20 May 2026.
//
//  This file has the builtin functions for add, sub, mul, div, mod, neg,
//  eq, ne, lt, le, gt, ge, and, or, not, incr, decr.
//

import Foundation

// Arithmetic builtins.
extension Program {

    /// Addition function.
    func bltinAdd(_ args: [ParsedExpr]) async throws -> ProgramValue {
        let arg1 = try await self.evaluate(args[0])
        let arg2 = try await self.evaluate(args[1])
        let result = ProgramValue.addPValues(arg1, arg2)
        if result == .null {
            throw RuntimeError("add requires two integers, two floats, or two strings",
                               line: args[0].line)
        }
        return result
    }

    /// Subtraction function.
    func bltinSub(_ args: [ParsedExpr]) async throws -> ProgramValue {
        let arg1 = try await self.evaluate(args[0])
        let arg2 = try await self.evaluate(args[1])
        let result = ProgramValue.subPValues(arg1, arg2)
        guard result != .null else {
            throw RuntimeError("sub requires two integers or two floats",
                                            line: args[0].line)
        }
        return result
    }

    /// Multiplication function.
    func bltinMul(_ args: [ParsedExpr]) async throws -> ProgramValue {
        let arg1 = try await self.evaluate(args[0])
        let arg2 = try await self.evaluate(args[1])
        let result = ProgramValue.mulPValues(arg1, arg2)
        guard result != .null else {
            throw RuntimeError("mul requires two integers or two floats",
                                            line: args[0].line)
        }
        return result
    }

    /// Division function.
    func bltinDiv(_ args: [ParsedExpr]) async throws -> ProgramValue {
        let arg2 = try await self.evaluate(args[1])
        if arg2 == .integer(0) || arg2 == .double(0.0) { // Check for zero divisor.
            throw RuntimeError("division by zero is not allowed",
                                            line: args[1].line)
        }
        let arg1 = try await self.evaluate(args[0])
        let result = ProgramValue.divPValues(arg1, arg2)
        guard result != .null else {
            throw RuntimeError("div requires two integers or two floats",
                                            line: args[0].line)
        }
        return result
    }

    /// Modulus function.
    func bltinMod(_ args: [ParsedExpr]) async throws -> ProgramValue {
        let arg1 = try await self.evaluate(args[0])
        let arg2 = try await self.evaluate(args[1])
        guard case let .integer(left) = arg1, case let .integer(right) = arg2 else { // Only integers.
            throw RuntimeError("mod requires two integer args",
                                            line: args[0].line)
        }
        if right == 0 { // Check for zero.
            throw RuntimeError("modulo by zero not allowed", line: args[0].line)
        }
        return .integer(left % right)
    }

    /// Negation function.
    func bltinNeg(_ args: [ParsedExpr]) async throws -> ProgramValue {
        // Evaluate the argument and check that it's numeric.
        let arg = try await self.evaluate(args[0])
        if !ProgramValue.isNumeric(arg) {
            throw RuntimeError("neg requires a numeric arg", line: args[0].line)
        }
        let result = ProgramValue.negPValue(arg)
        if result == .null {
            throw RuntimeError("neg requires a numeric arg", line: args[0].line)
        }
        return result
    }
}

/// Comparison builtins.
extension Program {

    /// Equal predicate.
    func bltinEq(_ args: [ParsedExpr]) async throws -> ProgramValue {
        let a = try await evaluate(args[0])
        let b = try await evaluate(args[1])
        return .boolean(a == b)
    }

    /// Not equal predicate.
    func bltinNe(_ args: [ParsedExpr]) async throws -> ProgramValue {
        let a = try await evaluate(args[0])
        let b = try await evaluate(args[1])
        return .boolean(a != b)
    }

    /// Less than predicate.
    func bltinLt(_ args: [ParsedExpr]) async throws -> ProgramValue {
        let a = try await evaluate(args[0])
        let b = try await evaluate(args[1])
        return ProgramValue.compare(a, b, using: <)
    }

    /// Less than or equal predicate.
    func bltinLe(_ args: [ParsedExpr]) async throws -> ProgramValue {
        let a = try await evaluate(args[0])
        let b = try await evaluate(args[1])
        return ProgramValue.compare(a, b, using: <=)
    }

    /// Greater than predicate.
    func bltinGt(_ args: [ParsedExpr]) async throws -> ProgramValue {
        let a = try await evaluate(args[0])
        let b = try await evaluate(args[1])
        return ProgramValue.compare(a, b, using: >)
    }

    /// Greator than or equal predicate.
    func bltinGe(_ args: [ParsedExpr]) async throws -> ProgramValue {
        let a = try await evaluate(args[0])
        let b = try await evaluate(args[1])
        return ProgramValue.compare(a, b, using: >=)
    }
}

// Increment and decrement builtins.
extension Program {

    /// Increment function.
    func bltinIncr(_ args: [ParsedExpr]) throws -> ProgramValue {
        // Argument must be an identifier.
        guard case let .identifier(name) = args[0].kind else {
            throw RuntimeError("incr: arg must be a variable", line: args[0].line)
        }
        // The identifer must be in a symbol table and have an integer value.
        guard let current = lookupSymbol(name) else {
            throw RuntimeError("incr: '\(name)' is not defined", line: args[0].line)
        }
        guard case let .integer(i) = current else {
            throw RuntimeError("incr: arg must be an integer variable", line: args[0].line)
        }
        // Store back the incremented value.
        let newVal = ProgramValue.integer(i + 1)
        assignToSymbol(name, value: newVal)
        return newVal
    }

    // Decrement function.
    func bltinDecr(_ args: [ParsedExpr]) throws -> ProgramValue {
        // Argument must be an identifier.
        guard case let .identifier(name) = args[0].kind else {
            throw RuntimeError("decr() expects a variable name",
                                         line: args[0].line)
        }
        // The identifer must be in a symbol table and have an integer value.
        guard let current = lookupSymbol(name) else {
            throw RuntimeError("decr(): variable '\(name)' is not defined",
                                               line: args[0].line)
        }
        guard case let .integer(i) = current else {
            throw RuntimeError("decr() requires an integer variable",
                                            line: args[0].line)
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
    func bltinAnd(_ args: [ParsedExpr]) async throws -> ProgramValue {
        for arg in args {
            if await !(try evaluate(arg).toBool) {
                return .falseProgramValue
            }
        }
        return .trueProgramValue
    }

    /// Logical or operation.
    func bltinOr(_ args: [ParsedExpr]) async throws -> ProgramValue {
        for arg in args {
            if try await evaluate(arg).toBool {
                return .trueProgramValue
            }
        }
        return .falseProgramValue
    }

    /// Logical not operation.
    func bltinNot(_ args: [ParsedExpr]) async throws -> ProgramValue {
        return try await evaluate(args[0]).toBool ? .falseProgramValue : .trueProgramValue
    }
}

extension Program {
    func bltinOrd(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let value = try await evaluate(args[0])

        guard case let .integer(n) = value else {
            return .null
        }

        let words = [
            "first", "second", "third", "fourth",
            "fifth", "sixth", "seventh", "eighth",
            "ninth", "tenth", "eleventh", "twelfth"
        ]

        if n < 1 {
            return .string(String(n))
        }

        if n <= words.count {
            return .string(words[n - 1])
        }

        let suffix: String
        if (11...13).contains(n % 100) {
            suffix = "th"
        } else {
            switch n % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }

        return .string("\(n)\(suffix)")
    }
}

