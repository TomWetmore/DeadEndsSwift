//
//  Interpret.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 7 April 2026.
//  Last changed on 31 August 2026.
//
//  This file has the interpreters for all statement types except the
//  foreach statement

import Foundation

/// Result values returned by the interpreter methods.
public enum InterpResult: Sendable {

    case okay  // Normal.
    case returning(ProgramValue?)  // Return statement.
    case breaking  // Break statement.
    case continuing  // Continue statement.
    case error  // Error result.
}

/// Interpreters for all statement types except the foreach statement. Each
/// takes one or more immutable parsed entities and returns an interp result.

extension Program {

    /// Interpret a list of statements. The argument is a list of parsed statements.
    func interpStmtList(_ stmts: [ParsedStatement]) async throws -> InterpResult {

        for stmt in stmts {
            let result = try await interpStatement(stmt)
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

    /// Interpret a statement. The argument is a parsed statement. The method checks
    /// the type of the statement and calls the interpreter for that type.
    func interpStatement(_ stmt: ParsedStatement) async throws -> InterpResult {
        
        try await tick(line: stmt.line)  // Lazy man infinite loop protection.

        switch stmt.kind {
        case .callStatement(let call):
            return try await interpProcCall(call)
        case .whileStatement(let whileStmt):
            return try await interpWhile(whileStmt)
        case .ifStatement(let ifStmt):
            return try await interpIf(ifStmt)
        case .returnStatement(let ret):
            return try await interpReturn(ret)
        case .breakStatement:
            return .breaking
        case .continueStatement:
            return .continuing
        case .forEachStatement(let stmt):
            return try await interpForEach(stmt)
        case .expressionStatement(let expr):
            let pvalue: ProgramValue = try await evaluate(expr)
            if case let .string(string) = pvalue {
                self.output.write(string)
            }
            return .okay
        }
    }

    /// Interpret a while statement.
    func interpWhile(_ whileStmt: ParsedWhileStmt) async throws -> InterpResult {

        while true {
            if await !(try evalCondition(whileStmt.condition)) { break }
            let result = try await interpStmtList(whileStmt.body)
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
    func interpIf(_ ifStmt: ParsedIfStmt) async throws -> InterpResult {

        if try await evalCondition(ifStmt.condition) {
            return try await interpStmtList(ifStmt.thenBody)
        }
        for elseIf in ifStmt.elseIfs {
            if try await evalCondition(elseIf.condition) {
                return try await interpStmtList(elseIf.body)
            }
        }
        if let elseBody = ifStmt.elseBody {
            return try await interpStmtList(elseBody)
        }
        return .okay
    }

    /// Interpret a return statement.
    func interpReturn(_ stmt: ParsedReturnStmt) async throws -> InterpResult {

        if stmt.values.isEmpty { return .returning(nil) }
        return try await .returning(evaluate(stmt.values[0]))
    }

    /// Interpret a procedure call statement.
    func interpProcCall(_ procCall: ParsedCallStatement) async throws -> InterpResult {

        let name = procCall.name
        let procDef = try requireProcDefn(name, line: procCall.line)
        let nArgs = procCall.args.count
        let nParams = procDef.params.count

        guard nArgs == nParams else {
            throw RuntimeError(
                "\(name) expects \(nParams) args, got \(nArgs)",
                line: procCall.line
            )
        }
        // Eval the args in the caller's context; add their values to a symbol table.
        var table: SymbolTable = [:]
        for (param, arg) in zip(procDef.params, procCall.args) {
            table[param] = try await evaluate(arg)
        }
        // Create the run time frame for the callee.
        let frame = RuntimeFrame(name: name, kind: .proc, defnLine: procDef.line,
            callLine: procCall.line, params: procDef.params, symbols: table)
        pushCallFrame(frame)
        defer { popCallFrame() }
        // Interpret the body of the proc.
        return try await interpStmtList(procDef.body)
    }
}
