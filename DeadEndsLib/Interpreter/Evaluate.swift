//
//  Evaluate.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 7 April 2026.
//  Last changed on 9 April 2026.
//

import Foundation

extension Program {

    // Generic evaluator. Handles .identifier, .integer, .double, .string, .functionCall,
    // and builtinCall.
    func evaluate(_ expr: ParsedExpr) throws -> ProgramValue {

        switch expr {
        case .identifier(let string): // Lookup variables in symbol tables.
            return try evaluateIdent(string)
//        case .builtinCall(let name, let args): // Builtin Swift functions.
//            return try evaluateBuiltin(name, args: args)
//        case .funcCall(let name, let args): // User-defined functions.
//            return try evaluateFunction(name, args: args)
        case .intConst(let integer): // Simple integer.
            return ProgramValue.integer(integer)
        case .stringConst(let string): // Simple string.
            return ProgramValue.string(string)
        case .floatConst(let float): // Simple float.
            return ProgramValue.double(float) // TODO: Inconsistent use of .float and .double.
        default:
            throw RuntimeError.undefinedFunction("Cannot evaluate \(String(describing: expr))")
        }
    }

    func evalCondition(_ cond: ParsedCondition) -> Bool {
        return true
    }

    // evaluateIdent evaluates an identifer by looking it up in the symbol tables and returning its value.
    func evaluateIdent(_ ident: String) throws -> ProgramValue {
        guard let value = lookupSymbol(ident) else {
            throw RuntimeError.undefinedSymbol("Undefined variable: \(ident)")
        }
        return value
    }
}

extension Program {
    
//    func evaluateBuiltin(_ name: String, args: [ParsedExpr]) throws -> ProgramValue {
//        guard let builtin = builtins[name] else {  // Get builtin function.
//            throw RuntimeError.undefinedSymbol("Unknown builtin function: \(name)")
//        }
//        guard (builtin.minArgs...builtin.maxArgs).contains(args.count) else {  // Check arg count.
//            throw RuntimeError.invalidArguments(
//                "\(name)() expects \(builtin.minArgs)-\(builtin.maxArgs) args, got \(args.count)"
//            )
//        }
//        return try builtin.function(args)  // Call builtin.
//    }

    // Evaluate a user function.
//    func evaluateFunction(_ name: String, args: [ParsedExpr]) throws -> ProgramValue {
//        guard let funcDef = functionTable[name] else {
//            throw RuntimeError.undefinedSymbol("Function \(name) is not defined")
//        }
//        let nParams = funcDef.params.count
//        let nArgs = args.count
//        guard nParams == nArgs else {
//            throw RuntimeError.invalidArguments("Function \(name) expects \(nParams) arguments, got \(nArgs)")
//        }
//        var frame: SymbolTable = [:]  // Create frame and bind the args to params.
//        for (param, arg) in zip(funcDef.params, args) {
//            let value = try evaluate(arg)
//            frame[param] = value
//        }
//
//        pushCallFrame(frame)  // Push frame on stack; defer the pop.
//        defer { popCallFrame() }
//
//        let result = try interpret(funcDef.body)  // Evaluate function by interpreting body.
//        switch result {
//        case .returning(let value):
//            return value ?? .null // Treat return() as returning null.
//
//        case .okay: return .null // Allow user functions to not return a value.
//
//        case .breaking, .continuing:
//            throw RuntimeError.invalidControlFlow("break/continue statement outside of loop")
//
//        case .error: // Probably not needed.
//            throw RuntimeError.executionFailed("Error  during function execution")
//        }
//    }
}

extension Program {

    /// Evaluate an expression and be sure it is a person.
    /// TODO: THIS LOOKS LIKE IT SHOULD RETURN A PERSON, NOT A GEDCOM NODE.
    /// DECIDE WHAT IT SHOULD DO. I BELIEVE IT SHOULD RETURN A PERSON RIGHT NOW.
    func evaluatePerson(_ pnode: ParsedExpr) throws -> GedcomNode? {
        let pvalue = try evaluate(pnode)
        guard case .gnode(let gnode) = pvalue, gnode.tag == GedcomTag.INDI else { return nil }
        // TODO: THIS SHOULD THROW AN ERROR.
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



