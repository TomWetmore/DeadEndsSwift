//
//  Evaluate.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 7 April 2026.
//  Last changed on 14 April 2026.
//

import Foundation

extension Program {

    // Evaluate an enumerated parsed expression.
    func evaluate(_ expr: ParsedExpr) throws -> ProgramValue {

        switch expr {
        case .identifier(let string): // Identifier.
            return try evaluateIdentifier(string)
        case .functionCall(let name, let args): // Builtin or user function.
            return try evaluateFunction(name, args: args)
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
    func evaluateIdentifier(_ ident: String) throws -> ProgramValue {

        guard let value = lookupSymbol(ident) else {
            throw RuntimeError.undefinedSymbol("Undefined variable: \(ident)")
        }
        return value
    }
}

extension Program {

    /// Evaluate a builtin or user function.
    func evaluateFunction(_ name: String, args: [ParsedExpr]) throws -> ProgramValue {
        if let _ = builtins[name] {
            return try evaluateBuiltin(name, args: args)
        } else {
            return try evaluateUserFunction(name, args: args)
        }
    }

    /// Evaluate a builtin function.
    func evaluateBuiltin(_ name: String, args: [ParsedExpr]) throws -> ProgramValue {
        guard let builtin = builtins[name] else {  // Get builtin function.
            throw RuntimeError.undefinedSymbol("Unknown builtin function: \(name)")
        }
        guard (builtin.minArgs...builtin.maxArgs).contains(args.count) else {
            throw RuntimeError.invalidArguments(
                "\(name)() expects \(builtin.minArgs)-\(builtin.maxArgs) args, got \(args.count)"
            )
        }
        return try builtin.function(args)  // Call builtin.
    }

    // Evaluate a user function.
    func evaluateUserFunction(_ name: String, args: [ParsedExpr]) throws -> ProgramValue {
        let funcDef: ParsedFuncDefn = try funcDefn(name)
        let nParams = funcDef.params.count
        let nArgs = args.count
        guard nParams == nArgs else {
            throw RuntimeError.invalidArguments("Function \(name) expects \(nParams) arguments, got \(nArgs)")
        }
        var frame: SymbolTable = [:]  // Create frame and bind the args to params.
        for (param, arg) in zip(funcDef.params, args) {
            let value = try evaluate(arg)
            frame[param] = value
        }

        pushCallFrame(frame)  // Push frame on stack; defer the pop.
        defer { popCallFrame() }

        let result = try interpStmtList(funcDef.body)  // Evaluate function by interpreting body.
        switch result {
        case .returning(let value):
            return value ?? .null // Treat return() as returning null.
        case .okay:
            return .null // Allow user functions to not return a value.
        case .breaking, .continuing:
            throw RuntimeError.invalidControlFlow("break/continue statement outside of loop")
        case .error: // Probably not needed.
            throw RuntimeError.executionFailed("Error  during function execution")
        }
    }
}

// TODO: THESE ARE NOT FINAL IMPLEMENTATIONS.
extension Program {

    /// Evaluate an expression that should return a person root node.
    func evaluateIndi(_ pnode: ParsedExpr) throws -> GedcomNode? {
        let pvalue = try evaluate(pnode)
        /// Caller should check for nil and possibly throw an error.
        guard case .gnode(let gnode) = pvalue, gnode.tag == GedcomTag.INDI else { return nil }
        return gnode
    }


    func evaluateGedcomNode(_ expr: ParsedExpr) throws -> GedcomNode? {
        let pvalue = try evaluate(expr)
        guard case .gnode(let gnode) = pvalue else {
            return nil
        }
        return gnode
    }
}



