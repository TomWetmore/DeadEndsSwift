//
//  Interpret.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 7 April 2026.
//  Last changed on 14 April 2026.
//

import Foundation

/// Result values from the  interpreter methods.
public enum InterpResult {

    case okay  // Normal end.
    case returning(ProgramValue?)  // Return statement end.
    case breaking  // Break statement end.
    case continuing  // Continue statement end.
    case error  // Error result.
}

/// List of statements and enumerated statements.
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

    /// Interpret an enumerated statement.
    func interpStatement(_ stmt: ParsedStatement) throws -> InterpResult {
        
        switch stmt {
        case .callStatement(let call):
            return try interpProcCall(call)
        case .whileStatement(let whileStmt):
            return try interpWhile(whileStmt)
        case .ifStatement(let ifStmt):
            return try interpIf(ifStmt)
        case .returnStatement(let ret):
            return try interpReturn(ret)
        case .breakStatement:
            return .breaking
        case .continueStatement:
            return .continuing
        case .expressionStatement(let expr):
            let pvalue: ProgramValue = try evaluate(expr)
            if case let .string(string) = pvalue {
                self.output.write(string)
            }
            return .okay
        }
    }
}

/// While and if statements.
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

/// Return statement.
extension Program {

    /// Interpret a return statement.
    func interpReturn(_ stmt: ParsedReturnStmt) throws -> InterpResult {
        if stmt.values.isEmpty { return .returning(nil) }
        return try .returning(evaluate(stmt.values[0]))
    }
}

/// Procedure call statement
extension Program {

    /// Interpret a procedure call statement.
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

