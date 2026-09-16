//
//  Evaluate.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 7 April 2026.
//  Last changed on 16 September 2026.
//

import Foundation

/// Basic evaluators.
extension Program {

    /// Evaluate a parsed expression.
    func evaluate(_ expr: ParsedExpr) async throws -> ProgramValue {

        switch expr.kind {

        case .identifier(let string):
            return try evalIdentifier(string, line: expr.line)

        case .functionCall(let name, let args):
            return try await evalFunction(name, args: args, line: expr.line)

        case .integerConstant(let integer):
            return ProgramValue.integer(integer)

        case .stringConstant(let string):
            return ProgramValue.string(string)

        case .doubleConstant(let double):
            return ProgramValue.double(double)
        }
    }

    /// Evaluate an expression that must be an integer.
    func evalInteger(_ expr: ParsedExpr, errMsg: String) async throws -> Int {

        guard case let .integer(integer) = try await evaluate(expr) else {
            throw RuntimeError(errMsg, line: expr.line)
        }
        return integer
    }

    /// Evaluate an identifer by looking it up in a symbol table.
    func evalIdentifier(_ ident: String, line: Int) throws -> ProgramValue {

        guard let value = lookupSymbol(ident) else {
            throw RuntimeError("undefined variable: \(ident)", line: line)
        }
        return value
    }

}

//// Evaluate functions for function calls.
extension Program {

    /// Evaluate a builtin or user function.
    func evalFunction(_ name: String, args: [ParsedExpr], line: Int) async throws -> ProgramValue {

        if let _ = builtins[name] {
            return try await evalBuiltIn(name, args: args, line: line)
        } else {
            return try await evalUserFunc(name, args: args, line: line)
        }
    }

    /// Evaluate a built-in function.
    private func evalBuiltIn(_ name: String, args: [ParsedExpr], line: Int) async throws -> ProgramValue {

        guard let builtin = builtins[name] else {  // Get builtin function.
            throw RuntimeError("Unknown builtin function: \(name)", line: line)
        }
        guard (builtin.min...builtin.max).contains(args.count) else {
            throw RuntimeError(
                "\(name)() expects \(expectedArgs(builtin)) args, got \(args.count)",
                line: line)
        }
        return try await builtin.function(args)  // Call builtin.

        func expectedArgs(_ builtin: Builtin) -> String {
            if builtin.min == builtin.max {
                return "\(builtin.min)"
            } else {
                return "\(builtin.min)-\(builtin.max)"
            }
        }
    }

    // Evaluate a user function.
    func evalUserFunc(_ name: String, args: [ParsedExpr], line: Int) async throws -> ProgramValue {

        let funcDefn = try requireFuncDefn(name, line: line)
        let nParams = funcDefn.params.count
        let nArgs = args.count
        guard nParams == nArgs else {
            throw RuntimeError("func \(name): expects \(nParams) args, got \(nArgs)",
                                                line: line)
        }
        var table: SymbolTable = [:]  // Create a symbol table and bind the args to params.
        for (param, arg) in zip(funcDefn.params, args) {
            let value = try await evaluate(arg)
            table[param] = value
        }
        // Create the run time frame for the callee.
        let frame = RuntimeFrame(name: name, kind: .function, defnLine: funcDefn.line,
                                 callLine: line, params: funcDefn.params, symbols: table)
        pushCallFrame(frame)
        defer { popCallFrame() }

        // Evaluate the func by interpreting its body.
        let result = try await interpStmtList(funcDefn.body)
        
        switch result {

        case .returning(let value):
            return value ?? .null // Allow return().

        case .okay:
            return .null // Allow no return().

        case .breaking, .continuing:
            throw RuntimeError("Break or continue statement outside of loop", line: line)

        case .error:
            throw RuntimeError("Error during function execution", line: line)
        }
    }
}

extension Program {

    /// Evaluate a conditional expression.
    func evalCondition(_ cond: ParsedCondition) async throws -> Bool {

        switch cond {

        case .expr(let expr):
            let value = try await evaluate(expr)
            return value.toBool

        case .assign(let name, let expr):
            let value = try await evaluate(expr)
            assignToSymbol(name, value: value)
            return value.toBool
        }
    }


}

// Evaluate functions for records.
extension Program {

    /// Evaluate an expression that should return a person.
    func evalPerson(_ expr: ParsedExpr, errMsg: String) async throws -> Person {

        let value = try await evaluate(expr)
        guard case .person(let person) = value else {
            throw RuntimeError(errMsg, line: expr.line)
        }
        return person
    }

    /// Evaluate an expression for an optional person.
    func evalPersonOpt(_ expr: ParsedExpr, errMsg: String) async throws -> Person? {

        switch try await evaluate(expr) {

        case .person(let person): return person
        case .null: return nil
        default: throw RuntimeError(errMsg, line: expr.line)
        }
    }

    /// Evaluate an expression for an optional family.
    func evalFamilyOpt(_ expr: ParsedExpr, errMsg: String) async throws -> Family? {

        switch try await evaluate(expr) {

        case .family(let family): return family
        case .null: return nil
        default: throw RuntimeError(errMsg, line: expr.line)
        }
    }

    /// Evaluate an expression for an optional gedcom node.
    func evalGedcomNodeOpt(_ expr: ParsedExpr, errMsg: String) async throws -> GedcomNode? {

        switch try await evaluate(expr) {

        case .gnode(let gnode): return gnode
        case .null: return nil
        default: throw RuntimeError(errMsg, line: expr.line)
        }
    }
}

/// Evaluators for person sets.
extension Program {

    /// Evaluate an expression for a a person set.
    func evalPersonSet(_ expr: ParsedExpr, errMsg: String)
        async throws -> PersonSet<ProgramValue> {

        guard case .personset(let personset) = try await evaluate(expr) else {
            throw RuntimeError(errMsg, line: expr.line)
        }
        return personset
    }
}
