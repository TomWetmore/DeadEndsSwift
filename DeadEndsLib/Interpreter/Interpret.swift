//
//  Interpret.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 7 April 2026.
//  Last changed on 14 April 2026.
//

import Foundation

public enum InterpResult {
    case okay
    case returning(ProgramValue?)
    case breaking
    case continuing
    case error
}

extension Program {

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
            let pvalue: ProgramValue = try evaluate(expr)
            if case let .string(string) = pvalue {
                print(string, terminator: "")
            }
            return .okay
        }
    }
}

extension Program {

    /// Interpret a while statement.
    func interpWhile(_ whileStmt: ParsedWhileStmt) throws -> InterpResult {
        while true {
            if !(try evalCondition(whileStmt.condition)) { break }
            let result = try interpStmtList(whileStmt.body)
            switch result {
            case .breaking:
                return .okay
            case .returning:
                return result
            case .error:
                return .error
            case .continuing, .okay:
                continue
            }
        }
        return .okay
    }

    /// Interpret an if statement.
    func interpIf(_ ifStmt: ParsedIfStmt) throws -> InterpResult {
        if try evalCondition(ifStmt.condition) {
            return try interpStmtList(ifStmt.thenBody)
        }
        for elseIf in ifStmt.elseIfs {
            if try evalCondition(elseIf.condition) {
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
        let procDef = try procDefn(name)
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
}

