//
//  Evaluate.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 7 April 2026.
//  Last changed on 2 May 2026.
//

import Foundation

extension Program {

    // Evaluate an enumerated parsed expression.
    func evaluate(_ expr: ParsedExpr) throws -> ProgramValue {

        switch expr.kind {
        case .identifier(let string): // Identifier.
            return try evaluateIdentifier(string, line: expr.line)
        case .functionCall(let name, let args): // Builtin or user function.
            return try evaluateFunction(name, args: args, line: expr.line)
        case .integerConstant(let integer): // Integer.
            return ProgramValue.integer(integer)
        case .stringConstant(let string): // String.
            return ProgramValue.string(string)
        case .doubleConstant(let double): // Double.
            return ProgramValue.double(double)
        }
    }

    /// Evaluate a conditional expression.
    func evalCondition(_ cond: ParsedCondition) throws -> Bool {

        switch cond {
        case .expr(let expr):
            let value = try evaluate(expr)
            return value.toBool()
        case .assign(let name, let expr):
            let value = try evaluate(expr)
            assignToSymbol(name, value: value)
            return value.toBool()
        }
    }

    /// Evaluate an identifer by looking it up in a symbol table.
    func evaluateIdentifier(_ ident: String, line: Int) throws -> ProgramValue {

        guard let value = lookupSymbol(ident) else {
            // TODO: Set a line number for the identifier.
            throw RuntimeError.undefinedSymbol("undefined variable: \(ident)", line: line)
        }
        return value
    }
}

extension Program {

    /// Evaluate a builtin or user function.
    func evaluateFunction(_ name: String, args: [ParsedExpr], line: Int) throws -> ProgramValue {
        if let _ = builtins[name] {
            return try evaluateBuiltin(name, args: args, line: line)
        } else {
            return try evaluateUserFunction(name, args: args, line: line)
        }
    }

    /// Evaluate a builtin function.
    private func evaluateBuiltin(_ name: String, args: [ParsedExpr], line: Int) throws -> ProgramValue {
        guard let builtin = builtins[name] else {  // Get builtin function.
            throw RuntimeError.undefinedSymbol("Unknown builtin function: \(name)",
                                               line: line)
        }
        guard (builtin.minArgs...builtin.maxArgs).contains(args.count) else {
            throw RuntimeError.invalidArguments(
                "\(name)() expects \(expectedArgs(builtin)) args, got \(args.count)",
                line: line)
        }
        return try builtin.function(args)  // Call builtin.

        func expectedArgs(_ builtin: Builtin) -> String {
            if builtin.minArgs == builtin.maxArgs {
                return "\(builtin.minArgs)"
            } else {
                return "\(builtin.minArgs)-\(builtin.maxArgs)"
            }
        }
    }

    // Evaluate a user function.
    func evaluateUserFunction(_ name: String, args: [ParsedExpr], line: Int) throws -> ProgramValue {

        let funcDefn = try requireFuncDefn(name, line: line)
        let nParams = funcDefn.params.count
        let nArgs = args.count
        guard nParams == nArgs else {
            throw RuntimeError.invalidArguments("func \(name): expects \(nParams) args, got \(nArgs)",
                                                line: line)
        }
        var table: SymbolTable = [:]  // Create frame and bind the args to params.
        for (param, arg) in zip(funcDefn.params, args) {
            let value = try evaluate(arg)
            table[param] = value
        }

        let frame = RuntimeFrame(
            name: name,
            kind: .function,
            defnLine: funcDefn.line,
            callLine: line,
            params: funcDefn.params,
            symbols: table
        )
        pushCallFrame(frame)  // Push frame on stack; defer the pop.
        defer { popCallFrame() }

        let result = try interpStmtList(funcDefn.body)  // Evaluate function by interpreting body.
        switch result {
        case .returning(let value):
            return value ?? .null // Treat return() as returning null.
        case .okay:
            return .null // Allow user functions to not return a value.
        case .breaking, .continuing:
            throw RuntimeError.invalidControlFlow("break/continu statement outside of loop", line: line) // TODO: This line should be the line of the break/continue!!!
        case .error: // Probably not needed.
            throw RuntimeError.executionFailed("Error during function execution", line: line)
        }
    }
}

// TODO: THESE ARE NOT FINAL IMPLEMENTATIONS.
extension Program {

    /// Evaluate an expression that should return a person.
    func evaluatePerson(_ expr: ParsedExpr, errMessage: String) throws -> Person {

        let value = try evaluate(expr)
        guard case .person(let person) = value else {
            throw RuntimeError.typeMismatch(errMessage, line: expr.line)
        }
        return person
    }

    /// Evaluate an expression for an optioanlaui person; throw error if not a person.
    func evaluatePersonOpt(_ expr: ParsedExpr, errMessage: String) throws -> Person? {

        let value = try evaluate(expr)
        guard case .null = value else { return nil }
        guard case .person(let person) = value else {
            throw RuntimeError.typeMismatch(errMessage, line: expr.line)
        }
        return person
    }


    func evaluateGedcomNodeOpt(_ expr: ParsedExpr, errMessage: String) throws -> GedcomNode? {

        switch try evaluate(expr) {
        case .gnode(let gnode):
            return gnode
        case .null:
            return nil
        default:
            throw RuntimeError.typeMismatch(errMessage, line: expr.line)
        }
    }
}

/// Evaluators for person sets.
extension Program {

    /// Evaluate a parsed expression to a person set.
    func evaluatePersonSet(_ expr: ParsedExpr, errMessage: String)
    throws -> PersonSet<ProgramValue> {

        guard case .personset(let personset) = try evaluate(expr) else {
            throw RuntimeError.runtimeError(errMessage, line: expr.line)
        }
        return personset
    }
}


