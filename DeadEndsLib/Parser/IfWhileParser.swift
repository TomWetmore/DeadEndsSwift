//
//  IfWhileParser.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 6 April 2026.
//  Last changed on 7 April 2026.
//

import Foundation
import Parsing

/// Enum for the two kinds of conditional expressions.
enum ParsedCondition: Equatable, CustomStringConvertible {

    case expr(ParsedExpr)
    case assign(String, ParsedExpr)

    var description: String {
        switch self {
        case .expr(let e):
            return "cond(\(e))"
        case .assign(let name, let expr):
            return "condAssign(\(name), \(expr))"
        }
    }
}

/// Structure that holds a parsed while statement.
struct ParsedWhileStmt: Equatable, CustomStringConvertible {
    let condition: ParsedCondition
    let body: [ParsedStmt]

    var description: String {
        "WHILE(\(condition)) { \(body) }"
    }
}

/// Enum for the statement types.
enum ParsedStmt: Equatable, CustomStringConvertible {
    case callStmt(ParsedCallStmt)
    case whileStmt(ParsedWhileStmt)
    case ifStmt(ParsedIfStmt)
    case returnStmt(ParsedReturnStmt)
    case breakStmt(ParsedBreakStmt)
    case continueStmt(ParsedContinueStmt)
    case exprStmt(ParsedExpr)

    var description: String {
        switch self {
        case .callStmt(let s):         return s.description
        case .whileStmt(let s):    return s.description
        case .ifStmt(let s):       return s.description
        case .returnStmt(let s):   return s.description
        case .breakStmt(let s):    return s.description
        case .continueStmt(let s): return s.description
        case .exprStmt(let e):         return "EXPRSTMT(\(e))"
        }
    }
}

struct ConditionParser: Parser {
    func parse(_ input: inout TokStream) throws -> ParsedCondition {
        let saved = input

        if let cond = try? parseAssignedCondition(&input) {
            return cond
        }

        input = saved
        let expr = try ExprParser().parse(&input)
        return .expr(expr)
    }

    private func parseAssignedCondition(_ input: inout TokStream) throws -> ParsedCondition {
        let name = try IdentifierToken().parse(&input)
        try ExactToken(kind: .comma).parse(&input)
        let expr = try ExprParser().parse(&input)
        return .assign(name, expr)
    }
}

/// Statement parser.
struct StmtParser: Parser {
    func parse(_ input: inout TokStream) throws -> ParsedStmt {
        guard let tok = input.first else {
            throw DeadEndsParseError()
        }
        switch tok.kind {
        case .whileTok:
            return .whileStmt(try WhileStmtParser().parse(&input))
        case .ifTok:
            return .ifStmt(try IfStmtParser().parse(&input))
        case .call:
            return .callStmt(try CallStmtParser().parse(&input))
        case .returnTok:
            return .returnStmt(try ReturnStmtParser().parse(&input))
        case .breakTok:
            return .breakStmt(try BreakStmtParser().parse(&input))
        case .continueTok:
            return .continueStmt(try ContinueStmtParser().parse(&input))
        default:
            return .exprStmt(try ExprParser().parse(&input))
        }
    }
}

/// Statement list parser.
struct StmtListParser: Parser {
    func parse(_ input: inout TokStream) throws -> [ParsedStmt] {
        var result: [ParsedStmt] = []

        while let tok = input.first, tok.kind != .rBrace, tok.kind != .eof {
            result.append(try StmtParser().parse(&input))
        }
        return result
    }
}

/// While statement parser.
struct WhileStmtParser: Parser {

    /// Parse a while statement.
    func parse(_ input: inout TokStream) throws -> ParsedWhileStmt {
        try ExactToken(kind: .whileTok).parse(&input)
        try ExactToken(kind: .lParen).parse(&input)
        let condition = try ConditionParser().parse(&input)
        try ExactToken(kind: .rParen).parse(&input)
        let body = try BlockParser().parse(&input)
        return ParsedWhileStmt(condition: condition, body: body)
    }
}

/// Block parser.
struct BlockParser: Parser {

    /// Parse a statement block.
    func parse(_ input: inout TokStream) throws -> [ParsedStmt] {
        try ExactToken(kind: .lBrace).parse(&input)
        let stmts = try StmtListParser().parse(&input)
        try ExactToken(kind: .rBrace).parse(&input)
        return stmts
    }
}


struct ParsedIfStmt: Equatable, CustomStringConvertible {
    let condition: ParsedCondition
    let thenBody: [ParsedStmt]
    let elseIfs: [ParsedElseIf]
    let elseBody: [ParsedStmt]?

    var description: String {
        "IF(\(condition)) THEN \(thenBody) ELSIFS \(elseIfs) ELSE \(String(describing: elseBody))"
    }
}

struct ParsedElseIf: Equatable, CustomStringConvertible {
    let condition: ParsedCondition
    let body: [ParsedStmt]

    var description: String {
        "ELSIF(\(condition)) \(body)"
    }
}

struct IfStmtParser: Parser {
    func parse(_ input: inout TokStream) throws -> ParsedIfStmt {
        try ExactToken(kind: .ifTok).parse(&input)
        try ExactToken(kind: .lParen).parse(&input)
        let condition = try ConditionParser().parse(&input)
        try ExactToken(kind: .rParen).parse(&input)

        let thenBody = try BlockParser().parse(&input)

        var elseIfs: [ParsedElseIf] = []
        while true {
            let saved = input
            if let elseIfClause = try? parseElseIf(&input) {
                elseIfs.append(elseIfClause)
            } else {
                input = saved
                break
            }
        }
        let saved = input
        let elseBody = (try? parseElse(&input)) ?? {
            input = saved
            return nil
        }()
        return ParsedIfStmt(
            condition: condition,
            thenBody: thenBody,
            elseIfs: elseIfs,
            elseBody: elseBody
        )
    }

    private func parseElseIf(_ input: inout TokStream) throws -> ParsedElseIf {
        try ExactToken(kind: .elsif).parse(&input)
        try ExactToken(kind: .lParen).parse(&input)
        let condition = try ConditionParser().parse(&input)
        try ExactToken(kind: .rParen).parse(&input)

        let body = try BlockParser().parse(&input)
        return ParsedElseIf(condition: condition, body: body)
    }

    private func parseElse(_ input: inout TokStream) throws -> [ParsedStmt] {
        try ExactToken(kind: .elseTok).parse(&input)
        return try BlockParser().parse(&input)
    }
}
