//
//  Interpret.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 7 April 2026.
//  Last changed on 12 April 2026.
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

extension Program {

    /// Interpret a statement.
    func interpStatement(_ stmt: ParsedStatement) throws -> InterpResult {
        
        switch stmt {
        case .callStatement(let call):
            return try interpProcCall(call)
        case .whileStatement(let whileStmt):
            return try interpWhile(whileStmt)
        case .ifStatement(let ifStmt):
            return try interpIf(ifStmt)
        case .returnStatement(let ret):
            //return try interpReturn(ret)
            return .returning(nil) // REPLACE WITH CORRECT STUFF.
        case .breakStatement:
            return .breaking
        case .continueStatement:
            return .continuing
        case .expressionStatement(let expr):
            _ = try evaluate(expr)
            return .okay
        }
    }
}

extension Program {

    /// Interpret a while statement.
    func interpWhile(_ whileStmt: ParsedWhileStmt) throws -> InterpResult {
        while true {
            if !(evalCondition(whileStmt.condition)) { break }
            let result = try interpStmtList(whileStmt.body)
            switch result {
            case .breaking:
                return .breaking
            case .returning:
                return result
            case .error:
                return .error
            case .continuing, .okay:
                continue
            }
        }
        return .error
    }

    /// Interpret an if statement.
    func interpIf(_ ifStmt: ParsedIfStmt) throws -> InterpResult {
        if evalCondition(ifStmt.condition) {
            return try interpStmtList(ifStmt.thenBody)
        }
        for elseIf in ifStmt.elseIfs {
            if evalCondition(elseIf.condition) {
                return try interpStmtList(elseIf.body)
            }
        }

        if let elseBody = ifStmt.elseBody {
            return try interpStmtList(elseBody)
        }
        return .okay
    }
}

func interpReturn(_ ret: ParsedReturnStmt) throws -> InterpResult {
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
//
//            case let .returnState(resultExpr):
//                let returnValue = try resultExpr.map { try evaluate($0) }
//                return .returning(returnValue)
//            default:
//                throw RuntimeError.runtimeError("Unhandled statement type: \(node.kind)")
//        }
//        return .okay // TODO: Can this be reached? Or does it just keep the compiler happy?
//    }
//

extension Program {

    func interpBreak() -> InterpResult {
        .breaking
    }

    func interpContinue() -> InterpResult {
        .continuing
    }

//    func interpReturn(_ expr: ParsedExpr?) -> InterpResult {
//        // If there is no expression
//        if expr == nil { return .returning(nil) }
//
//        let returnValue = try? expr.map { evaluate($0) }
//        return .returning(returnValue)
//    }
}

extension Program {

    /// Interpret a ParsedCallStmt.
    func interpProcCall(_ procCall: ParsedCallStatement) throws -> InterpResult {

        let name = procCall.name
        let procDef = try procedureDefinition(name)
        let nArgs = procCall.args.count
        let nParams = procDef.params.count
        guard nArgs == nParams else { // Check numbers of args and params.
            throw RuntimeError.invalidArguments("Proc '\(name)' expects \(nParams) arguments, got \(nArgs)")
        }
        var table: SymbolTable = [:] // Prepare the symbol table for the procedure.
        for (param, arg) in zip(procDef.params, procCall.args) {
            table[param] = try evaluate(arg)
        }
        pushCallFrame(table)
        defer { popCallFrame() }
        return try interpStmtList(procDef.body) // Call user procedure.
    }

    /// Interpret a list of statements.
    func interpStmtList(_ stmts: [ParsedStatement]) throws -> InterpResult {
        for stmt in stmts {
            let result = try interpStatement(stmt)
            switch result { 
            case .okay:
                continue 
            case .returning, .breaking, .continuing:
                return result
            case .error:
                return .error
            }
        }
        return .okay
    }
}

