//
//  Evaluate.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 7 April 2026.
//  Last changed on 10 July 2026.
//

import Foundation

extension Program {

    /// Evaluate a parsed expression that must be an integer.
    func evalInteger(_ expr: ParsedExpr, errMsg: String) async throws -> Int {

        guard case let .integer(integer) = try await evaluate(expr) else {
            throw RuntimeError(errMsg, line: expr.line)
        }
        return integer
    }

    // Evaluate a parsed expression.
    func evaluate(_ expr: ParsedExpr) async throws -> ProgramValue {

        switch expr.kind {
        case .identifier(let string): // Identifier.
            return try evalIdentifier(string, line: expr.line)
        case .functionCall(let name, let args): // Builtin or user function.
            return try await evalFunction(name, args: args, line: expr.line)
        case .integerConstant(let integer): // Integer.
            return ProgramValue.integer(integer)
        case .stringConstant(let string): // String.
            return ProgramValue.string(string)
        case .doubleConstant(let double): // Double.
            return ProgramValue.double(double)
        }
    }

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

    /// Evaluate an identifer by looking it up in a symbol table.
    func evalIdentifier(_ ident: String, line: Int) throws -> ProgramValue {

        guard let value = lookupSymbol(ident) else {
            // TODO: Set a line number for the identifier.
            throw RuntimeError("undefined variable: \(ident)", line: line)
        }
        return value
    }
}

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

        let frame = RuntimeFrame( // Create the run time frame that holds the symbol table.
            name: name,
            kind: .function,
            defnLine: funcDefn.line,
            callLine: line,
            params: funcDefn.params,
            symbols: table
        )
        pushCallFrame(frame) // Push the frame onto the run time stack; defer the pop.
        defer { popCallFrame() }

        let result = try await interpStmtList(funcDefn.body) // Eval the function by interpreting its body.
        switch result {
        case .returning(let value):
            return value ?? .null // Treat return() as returning null.
        case .okay:
            return .null // Allow user functions to not return a value.
        case .breaking, .continuing:
            throw RuntimeError("break/continue statement outside of loop", line: line)
        case .error: // Probably not needed.
            throw RuntimeError("Error during function execution", line: line)
        }
    }
}

extension Program {

    /// Evaluate an expression that should return a person.
    func evalPerson(_ expr: ParsedExpr, errMsg: String) async throws -> Person {

        let value = try await evaluate(expr)
        guard case .person(let person) = value else {
            throw RuntimeError(errMsg, line: expr.line)
        }
        return person
    }

    /// Evaluate an expression for an optional person; allows null-forwarding of persons.
    func evalPersonOpt(_ expr: ParsedExpr, errMsg: String) async throws -> Person? {

        switch try await evaluate(expr) {
        case .person(let person):
            return person
        case .null:
            return nil
        default:
            throw RuntimeError(errMsg, line: expr.line)
        }
    }

    /// Evaluate an expression for an optional gedcom nodei; allows null-forwarding of nodes.
    func evalGedcomNodeOpt(_ expr: ParsedExpr, errMsg: String) async throws -> GedcomNode? {

        switch try await evaluate(expr) {
        case .gnode(let gnode):
            return gnode
        case .null:
            return nil
        default:
            throw RuntimeError(errMsg, line: expr.line)
        }
    }
}

/// Evaluators for person sets.
extension Program {

    /// Evaluate a parsed expression to a person set.
    func evalPersonSet(_ expr: ParsedExpr, errMsg: String)
    async throws -> PersonSet<ProgramValue> {

        guard case .personset(let personset) = try await evaluate(expr) else {
            throw RuntimeError(errMsg, line: expr.line)
        }
        return personset
    }
}


