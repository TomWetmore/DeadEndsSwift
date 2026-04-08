//
//  Interpret.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 7 April 2026.
//  Last changed on 7 April 2026.
//

import Foundation

//
//  Interpret.swift
//  This file has many of the functions that interpret DeadEnds program.
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 18 March 2025.
//  Last changed on 21 April 2025.
//

import Foundation

public enum InterpResult {
    case okay
    case returning(ProgramValue?)
    case breaking
    case continuing
    case error
}

public func runProgram(program: Program) throws {
    // Create a database.
}

func interpret(_ stmt: ParsedStmt) throws -> InterpResult {
    switch stmt {
    case .callStmt(let call):
        return try interpretProcedureCall(call)
    case .whileStmt(let whileStmt):
        return try interpretWhile(whileStmt)
    case .ifStmt(let ifStmt):
        return try interpretIf(ifStmt)
    case .returnStmt(let ret):
        return try interpretReturn(ret)
    case .breakStmt:
        return .breaking
    case .continueStmt:
        return .continuing
    case .exprStmt(let expr):
        _ = try evaluate(expr: expr)
        return .okay
    }
}

func interpretProcedureCall(_ call: ParsedCallStmt) throws -> InterpResult {
    return .error
}
func interpretWhile(_ whileStmt: ParsedWhileStmt) throws -> InterpResult {
    return .error
}
func interpretIf(_ ifStmt: ParsedIfStmt) throws -> InterpResult {
    return .error
}
func interpretReturn(_ ret: ParsedReturnStmt) throws -> InterpResult {
    return .error
}
func interpretContinue() -> InterpResult {
    return .error
}


//extension Program {
//
//    // interpret is the top level interpreter. Its parameter is a ProgramNode. It handles some kinds of ProgramNodes directly,
//    // and call separate functions for others.
//    func interpret(_ node: ProgramNode) throws -> InterpResult {
//        switch node.kind {
//            case let .string(string): // Output string value.
//                print(string, terminator: "")
//            case .integer, .double: // Ignore numbers.
//                break
//            case .identifier: // Output identifer value if it is a string.
//                let value = try evaluateIdent(node)
//                if case let .string(output) = value {
//                    print(output, terminator: "")
//                }
//            case .builtinCall: // Call builtin function.
//                let result = try evaluateBuiltin(node)
//                if case let .string(output) = result {
//                    print(output, terminator: "")
//                }
//            case let .procedureCall(name, _): // Call user defined procedure.
//                switch try interpretProcedure(node) {
//                    case .okay:
//                        break
//                    case .error:
//                        throw RuntimeError.runtimeError("Error calling procedure: \(name)")
//                    case .returning(let value):
//                        return .returning(value)
//                    case .breaking:
//                        return .breaking
//                    case .continuing:
//                        return .continuing
//                }
//            case .functionCall:
//                let result = try evaluateFunction(node)
//                if case let .string(output) = result {
//                    print(output, terminator: "")
//                }
//            case let .ifState(condition, thenc, elsec):
//                let result: Bool = try evaluateCondition(condition)
//                let blockToExecute = result ? thenc : elsec
//                if let block = blockToExecute {
//                    return try interpret(block)
//                }
//                return .okay
//            case let .whileState(condition, body):
//                while true {
//                    if !(try evaluateCondition(condition)) { break } // Break this while loop.
//                    let result = try interpret(body)
//                    switch result {
//                    case .breaking:
//                        break
//                    case .returning:
//                        return result
//                    case .error:
//                        return .error
//                    case .continuing, .okay:
//                        continue // Continue this loop.
//                    }
//                }
//                return .okay
//            case .breakState:
//                return .breaking
//            case .continueState:
//                return .continuing
//            case let .returnState(resultExpr):
//                let returnValue = try resultExpr.map { try evaluate($0) }
//                return .returning(returnValue)
//            case .block:
//                return try interpretBlock(node)
//            default:
//                throw RuntimeError.runtimeError("Unhandled statement type: \(node.kind)")
//        }
//        return .okay // TODO: Can this be reached? Or does it just keep the compiler happy?
//    }
//
//    // interpretBlock interperts a .block PNode.
//    func interpretBlock(_ pnode: ProgramNode) throws -> InterpResult {
//        guard case let .block(statements) = pnode.kind else {
//            throw RuntimeError.invalidSyntax("Expected a block node")
//        }
//        for statement in statements {
//            let result = try interpret(statement)
//            switch result { // Handle control flow.
//            case .okay:
//                continue // No control flow break, keep going
//            case .returning, .breaking, .continuing:
//                return result // Propagate return/break/continue upward
//            case .error:
//                return .error
//            }
//        }
//        return .okay
//    }
//
//    // interpretProcedure interprets a .procedureCall ProgramNode.
//    func interpretProcedure(_ pnode: ProgramNode) throws -> InterpResult {
//        guard case let .procedureCall(name, args) = pnode.kind else { // pnode must be a .procedureCall.
//            throw RuntimeError.invalidSyntax("Expected a procedure call")
//        }
//        guard let procDef = procedureTable[name] else { // Procedure called must exit.
//            throw RuntimeError.undefinedSymbol("Procedure '\(name)' not found")
//        }
//        guard case let .procedureDef(_, params, body) = procDef.kind else { // Overkill?
//            throw RuntimeError.invalidSyntax("Expected a procedure definition for '\(name)'")
//        }
//        guard args.count == params.count else { // Numbers of args and params must be the same.
//            throw RuntimeError.invalidArguments("Procedure '\(name)' expects \(params.count) arguments, got \(args.count)")
//        }
//        var table: SymbolTable = [:] // Create symbol table for the procedure.
//        for (param, arg) in zip(params, args) { // Bind the evaluated args to the params in the symbol table.
//            let value = try evaluate(arg) // Evaluate the argument.
//            table[param] = value // Bind the argument's value to the parameter.
//        }
//        pushCallFrame(table) // Push and pop the call frame.
//        defer { popCallFrame() }
//
//        return try interpret(body) // Interpret the procedure body.
//    }
//}
