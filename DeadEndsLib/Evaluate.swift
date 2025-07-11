//
//  Evaluate.swift
//  DeadEndsLib
//  This file has the functions that evaluate PNodes when the DeadEnds interpreter is running. The kinds of PNodes
//  that can be evaluated are .identifier, .integer, .double, .string, .functionCall, and .builtinCall.
//
//  Created by Thomas Wetmore on 21 March 2025.
//  Last changed on 21 April 2025.
//

import Foundation

// The evaluate functions are methods on Program, giving them access to the running program.
extension Program {

    // evaluate is the generic evaluator. It evaluates ProgramNodes that are evaluable and returns their values
    // as PValues. It handles .identifier, .integer, .double, .string, .functionCall, and builtinCall.
    // For .identifier, .builtinCall, and .functionCall it calls more specific functions.
    func evaluate(_ pnode: ProgramNode) throws -> ProgramValue {
        switch pnode.kind {
        case .identifier: // Variables are looked up in the symbol tables.
            return try evaluateIdent(pnode)

        case .builtinCall: // Builtin Swift functions.
            return try evaluateBuiltin(pnode)

        case .functionCall: // User-defined functions in the functionDefinition table.
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

    // evaluateCondition evaluates the conditions found on .if and .while ProgramNodes. A condition is a one or
    // two ProgramNode array. If there is one ProgramNode it is evaluated, coerced to Boolean and returned. If there are
    // two ProgramNode the first must be an .identifer; the second is evaluated and its value assigned to the
    // variable; the expression value is then coerced to Bool and returned.
    func evaluateCondition(_ condition: [ProgramNode]) throws -> Bool {
        guard condition.count == 1 || condition.count == 2 else { // Array must have one or two ProgramNodes.
            throw RuntimeError.invalidArguments("Condition must be one or two expressions")
        }
        let expr: ProgramNode
        var ident: String? = nil
        if condition.count == 2 { // First node should be an identifier.
            guard case let .identifier(string) = condition[0].kind else {
                throw RuntimeError.typeMismatch("First element in conditional must be an identifier")
            }
            ident = string
            expr = condition[1]
        } else {
            expr = condition[0]
        }
        let value = try evaluate(expr) // Evaluate the expression; does not have to be Bool.
        if let ident = ident { // If ident exists assign it the expression value.
            assignLocal(ident, value: value)
        }
        switch value { // Coerce the PValue to a Bool and return it.
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

// Extension with methods that evaluate the builtin and user defined functions.
extension Program {

    // evaluateBuiltinCall evaluates a built-in function.
    func evaluateBuiltin(_ node: ProgramNode) throws -> ProgramValue {

        // Make sure the ProgramNode is a .builtinCall kind.
        // TODO: This is overkilll
        guard case let .builtinCall(name, args) = node.kind else {
            throw RuntimeError.undefinedFunction("Expected a built-in function")
        }

        // Make sure there is a builtin function with the given name.
        guard let builtin = builtins[name] else {
            throw RuntimeError.undefinedSymbol("Unknown builtin function: \(name)")
        }

        // Check that there are the right number of arguments so the individual builtins don't have to.
        guard (builtin.minArgs...builtin.maxArgs).contains(args.count) else {
            throw RuntimeError.invalidArguments("\(name)() expects \(builtin.minArgs)-\(builtin.maxArgs) args, got \(args.count)")
        }

        // Call the builtin method.
        return try builtin.function(args)
    }

    // evaluateFunction evaluates a user-defined function.
    func evaluateFunction(_ pnode: ProgramNode) throws -> ProgramValue {

        // Make sure the ProgramNode is a .functionCall kind.
        // TODO: This is overkill.
        guard case let .functionCall(name, args) = pnode.kind else {
            throw RuntimeError.invalidSyntax("Expected a function call")
        }

        // Make sure there is a user defined function with the given name.
        guard let funcDef = functionTable[name] else {
            throw RuntimeError.undefinedSymbol("Function \(name) is not defined")
        }

        // Make sure the PNode found in the funnction table is a .functionDef kind.
        // TODO: This is overkill.
        guard case let .functionDef(_, params, body) = funcDef.kind else {
            throw RuntimeError.invalidSyntax("Expected function definition for \(name)")
        }

        // Make sure the numbers of argument and parameters match.
        guard params.count == args.count else {
            throw RuntimeError.invalidArguments("Function \(name) expects \(params.count) arguments, got \(args.count)")
        }

        // Create a SymbolTable frame for the function and bind the arguments to the parameters.
        var frame: SymbolTable = [:]
        for (param, arg) in zip(params, args) {
            let value = try evaluate(arg)
            frame[param] = value
        }

        // Push the new frame onto the stack; defer the pop so it happens however this method exits.
        pushCallFrame(frame)
        defer { popCallFrame() }

        // Evaluate the function by interpreting its body.
        let result = try interpret(body)
        switch result {
        case .returning(let value):
            return value ?? .null // Treat return() as returning null.

        case .okay: return .null // Allow user functions to be sloppy and not return anything.

        case .breaking, .continuing:
            throw RuntimeError.invalidControlFlow("break/continue statement outside of loop")
                
        case .error: // Probably not needed.
            throw RuntimeError.executionFailed("Error occurred during function execution")
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
