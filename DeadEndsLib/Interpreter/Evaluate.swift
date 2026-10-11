//
//  Evaluate.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 7 April 2026.
//  Last changed on 9 October 2026.
//

import Foundation

/// Evaluators for consants, identifiers (variables), and function calls (built-in
/// and user-defined).
///
extension Program {

    /// Evaluate a parsed expression. Based on the kind of the expression it may
    /// call a more specific evaluator.
    ///
    func evaluate(_ expr: ParsedExpr) async throws -> ProgramValue {

        switch expr.kind {

        case .identifier(let string):  // Lookup the value of an identifier.
            return try evalIdentifier(string, line: expr.line)

        case .functionCall(let name, let args):  // Evaluate a function call.
            return try await evalFunction(name, args: args, line: expr.line)

        case .integerConstant(let integer):  // Integer constant.
            return ProgramValue.integer(integer)

        case .stringConstant(let string):  // String constant.
            return ProgramValue.string(string)

        case .doubleConstant(let double):  // Double constant.
            return ProgramValue.double(double)
        }
    }

    /// Evaluate an expression that must be an integer.
    ///
    func evalInteger(_ expr: ParsedExpr, errMsg: String) async throws -> Int {

        guard case let .integer(integer) = try await evaluate(expr) else {
            throw RuntimeError(errMsg, line: expr.line)
        }
        return integer
    }

    /// Evaluate an identifer by looking it up in a symbol table.
    ///
    func evalIdentifier(_ ident: String, line: Int) throws -> ProgramValue {

        guard let value = lookupSymbol(ident) else {
            throw RuntimeError("undefined variable: \(ident)", line: line)
        }
        return value
    }

}

/// Evaluate the two types of function calls.
///
extension Program {

    /// Evaluate a builtin or user function.
    ///
    func evalFunction(_ name: String, args: [ParsedExpr], line: Int) async throws -> ProgramValue {

        if let _ = builtins[name] {
            return try await evalBuiltIn(name, args: args, line: line)
        } else {
            return try await evalUserFunc(name, args: args, line: line)
        }
    }

    /// Evaluate a built-in function.
    ///
    private func evalBuiltIn(_ name: String, args: [ParsedExpr], line: Int)
                                async throws -> ProgramValue {

        guard let builtin = builtins[name] else {  // Get builtin function.
            throw RuntimeError("Unknown builtin function: \(name)", line: line)
        }
        guard (builtin.min...builtin.max).contains(args.count) else {  // Check its arg count.
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

    /// Evaluate a user-defined function.
    ///
    func evalUserFunc(_ name: String, args: [ParsedExpr], line: Int) async throws -> ProgramValue {

        // Get the functions and check its argument count.
        let funcDefn = try requireFuncDefn(name, line: line)
        let nParams = funcDefn.params.count
        let nArgs = args.count
        guard nParams == nArgs else {
            throw RuntimeError("func \(name): expects \(nParams) args, got \(nArgs)",
                                                line: line)
        }

        // Create a symbol table and bind the arguments to the parameters.
        var table: SymbolTable = [:]
        for (param, arg) in zip(funcDefn.params, args) {
            let value = try await evaluate(arg)
            table[param] = value
        }

        // Create the run time stack frame for the callee and push on the stack.
        let frame = RuntimeFrame(name: name, kind: .function, defnLine: funcDefn.line,
                                 callLine: line, params: funcDefn.params, symbols: table)
        pushCallFrame(frame)
        defer { popCallFrame() }

        // Evaluate the function by interpreting its body.
        let result = try await interpStmtList(funcDefn.body)

        // Handle the result of calling the function.
        switch result {

        case .returning(let value):
            return value ?? .null // Allow the function to do return().

        case .okay:
            return .null // Allow the function to not return a value.

        case .breaking, .continuing:  // Cannot continue or break out of a function.
            throw RuntimeError("Break or continue statement outside of loop", line: line)

        case .error:
            throw RuntimeError("Error during function execution", line: line)
        }
    }
}

extension Program {

    /// Evaluate a conditional expression.
    ///
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

/// Evaluate functions for records.
///
extension Program {

    /// Evaluate an expression that must return a Person.
    ///
    func evalPerson(_ expr: ParsedExpr, errMsg: String) async throws -> Person {

        let value = try await evaluate(expr)
        guard case .person(let person) = value else {
            throw RuntimeError(errMsg, line: expr.line)
        }
        return person
    }

    /// Evaluate an expression that must return a Person or nil.
    ///
    func evalPersonOpt(_ expr: ParsedExpr, errMsg: String) async throws -> Person? {

        switch try await evaluate(expr) {

        case .person(let person): return person

        case .null: return nil

        default: throw RuntimeError(errMsg, line: expr.line)
        }
    }

    /// Evaluate an expression that must return a Family or nil.
    ///
    func evalFamilyOpt(_ expr: ParsedExpr, errMsg: String) async throws -> Family? {

        switch try await evaluate(expr) {

        case .family(let family): return family

        case .null: return nil

        default: throw RuntimeError(errMsg, line: expr.line)
        }
    }

    /// Evaluate an expression that must return a GedcomNode or nil.
    ///
    func evalGedcomNodeOpt(_ expr: ParsedExpr, errMsg: String) async throws -> GedcomNode? {

        switch try await evaluate(expr) {

        case .gnode(let gnode): return gnode

        case .null: return nil

        default: throw RuntimeError(errMsg, line: expr.line)
        }
    }
}

/// Evaluators for person sets.
///
extension Program {

    /// Evaluate an expression that must be a PersonSet.
    ///
    func evalPersonSet(_ expr: ParsedExpr, errMsg: String)
        async throws -> PersonSet {

        guard case .personset(let personset) = try await evaluate(expr) else {
            throw RuntimeError(errMsg, line: expr.line)
        }
        return personset
    }
}
