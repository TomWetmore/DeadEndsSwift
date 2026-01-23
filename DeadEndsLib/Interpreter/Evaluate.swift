//
//  Evaluate.swift
//  DeadEndsLib
//
//  This file holds functions that evaluate program nodes when the interpreter is running.
//  The kinds of PNodes evaluated are .identifier, .integer, .double, .string, .functionCall,
//  and .builtinCall.
//
//  Created by Thomas Wetmore on 21 March 2025.
//  Last changed on 19 January 2026.
//

import Foundation

// Evaluate functions are methods on Program, giving them access to the running program.
extension Program {

    // Generic evaluator. Handles .identifier, .integer, .double, .string, .functionCall,
    // and builtinCall.
    func evaluate(_ pnode: ProgramNode) throws -> ProgramValue {

        switch pnode.kind {
        case .identifier: // Lookup variables in symbol tables.
            return try evaluateIdent(pnode)
        case .builtinCall: // Builtin Swift functions.
            return try evaluateBuiltin(pnode)
        case .functionCall: // User-defined functions.
            return try evaluateFunction(pnode)
        case .integer(let integer): // Simple integer.
            return ProgramValue.integer(integer)
        case .string(let string): // Simple string.
            return ProgramValue.string(string)
        case .double(let float): // Simple float.
            return ProgramValue.double(float) // TODO: Inconsistent use of .float and .double.
        default:
            throw RuntimeError.undefinedFunction("Cannot evaluate \(String(describing: pnode.kind))")
        }
    }

    // Evaluate the condition on .if and .while program nodes. A condition is a one or two program
    // node array. If there is one node it is evaluated, coerced to bool and returned. If there are
    // two the first must be an .identifer; the second is evaluated and its value assigned to the
    // variable; the expression value is then coerced to Bool and returned.
    func evaluateCondition(_ condition: [ProgramNode]) throws -> Bool {

        guard condition.count == 1 || condition.count == 2 else {
            throw RuntimeError.invalidArguments("Condition must be one or two expressions")
        }
        let expr: ProgramNode
        var ident: String? = nil
        if condition.count == 2 { // First node must be an identifier.
            guard case let .identifier(string) = condition[0].kind else {
                throw RuntimeError.typeMismatch("First element in conditional must be an identifier")
            }
            ident = string
            expr = condition[1]
        } else {
            expr = condition[0]
        }
        let value = try evaluate(expr) // Evaluate the expression.
        if let ident = ident { // If ident exists assign it the value.
            assignLocal(ident, value: value)
        }
        switch value { // Coerce the value to Bool and return it.
            case .boolean(let bool):
                return bool
            case .integer(let integer):
                return integer != 0
            case .double(let double):
                return double != 0.0
            case .string(let string):
                return !string.isEmpty
            case .null:
                return false
            default:
                throw RuntimeError.typeMismatch("Cannot convert \(value) to boolean")
        }
    }
}

// Methods that evaluate the builtin and user defined functions.
extension Program {

    // Evaluate a built-in function.
    func evaluateBuiltin(_ node: ProgramNode) throws -> ProgramValue {

        guard case let .builtinCall(name, args) = node.kind else {
            throw RuntimeError.undefinedFunction("Expected a built-in function")
        }
        guard let builtin = builtins[name] else {  // Get builtin function.
            throw RuntimeError.undefinedSymbol("Unknown builtin function: \(name)")
        }
        guard (builtin.minArgs...builtin.maxArgs).contains(args.count) else {  // Check arg count.
            throw RuntimeError.invalidArguments(
                "\(name)() expects \(builtin.minArgs)-\(builtin.maxArgs) args, got \(args.count)"
            )
        }
        return try builtin.function(args)  // Call builtin.
    }

    // Evaluate a user-defined function.
    func evaluateFunction(_ pnode: ProgramNode) throws -> ProgramValue {

        guard case let .functionCall(name, args) = pnode.kind else {
            throw RuntimeError.invalidSyntax("Expected a function call")  // Sanity check.
        }
        guard let funcDef = functionTable[name] else {  // Get user-defined function.
            throw RuntimeError.undefinedSymbol("Function \(name) is not defined")
        }
        guard case let .functionDef(_, params, body) = funcDef.kind else {  // Sanity check.
            throw RuntimeError.invalidSyntax("Expected function definition for \(name)")
        }
        guard params.count == args.count else {  // Check arg count.
            throw RuntimeError.invalidArguments("Function \(name) expects \(params.count) arguments, got \(args.count)")
        }
        var frame: SymbolTable = [:]  // Create frame and bind the args to params.
        for (param, arg) in zip(params, args) {
            let value = try evaluate(arg)
            frame[param] = value
        }

        pushCallFrame(frame)  // Push frame on stack; defer the pop.
        defer { popCallFrame() }

        let result = try interpret(body)  // Evaluate function by interpreting body.
        switch result {
        case .returning(let value):
            return value ?? .null // Treat return() as returning null.

        case .okay: return .null // Allow user functions to not return a value.

        case .breaking, .continuing:
            throw RuntimeError.invalidControlFlow("break/continue statement outside of loop")
                
        case .error: // Probably not needed.
            throw RuntimeError.executionFailed("Error  during function execution")
        }
    }
}

// Program extension with more evaulate methods.
extension Program {

    // evaluateIdent evaluates an identifer by looking it up in the symbol tables and returning its value.
    func evaluateIdent(_ pnode: ProgramNode) throws -> ProgramValue {
        guard case let .identifier(name) = pnode.kind else {
            throw RuntimeError.invalidSyntax("Expected identifier node")
        }
        guard let value = lookupSymbol(name) else {
            throw RuntimeError.undefinedSymbol("Undefined variable: \(name)")
        }
        return value
    }

    // evaluateBoolean evaluates a ProgramNode expression are returns a boolean value.
    func evaluateBoolean(_ pnode: ProgramNode) throws -> ProgramValue {
        let pvalue = try evaluate(pnode)
        return ProgramValue.boolean(pvalueToBoolean(pvalue))
    }

    func pvalueToBoolean(_ pvalue: ProgramValue) -> Bool {
        switch pvalue {
        case .null: return false
        case .boolean(let b): return b
        case .integer(let i): return i != 0
        case .double(let f): return f != 0.0
        case .string(let s): return !s.isEmpty
        //case .gnode(let g): return g != nil
        //case .sequence(let s): return s != nil
        //case .list(let l): return l != nil
        default: return false
        }
    }

    func evaluatePerson(_ pnode: ProgramNode) throws -> GedcomNode? {
        let pvalue = try evaluate(pnode)
        guard case .gnode(let gnode) = pvalue, gnode.tag == "INDI" else { return nil }
        return gnode
    }

    func evaluateFamily(_ pnode: ProgramNode) throws -> GedcomNode? {
        let pvalue = try evaluate(pnode)
        guard case .gnode(let gnode) = pvalue, gnode.tag == "FAM" else { return nil }
        return gnode
    }

    func evaluateGedcomNode(_ pnode: ProgramNode) throws -> GedcomNode? {
        let pvalue = try evaluate(pnode)
        guard case .gnode(let gnode) = pvalue else {
            return nil
        }
        return gnode
    }
}
