//
//  IfWhileParser.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 6 April 2026.
//  Last changed on 6 April 2026.
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

/// Enum for the different statement types.
enum ParsedStmt: Equatable, CustomStringConvertible {
    case call(ParsedCallStmt)
    case whileStmt(ParsedWhileStmt)
    case ifStmt(ParsedIfStmt)
    case expr(ParsedExpr)

    var description: String {
        
        switch self {
        case .call(let s):      return s.description
        case .whileStmt(let s): return s.description
        case .ifStmt(let s):    return s.description
        case .expr(let e):      return "EXPRSTMT(\(e))"
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

    /// Parse a statement.
    func parse(_ input: inout TokStream) throws -> ParsedStmt {

        guard let tok = input.first else {
            throw DeadEndsParseError()
        }

        switch tok.kind {
        case .whileTok:
            return .whileStmt(try WhileStmtParser().parse(&input))
        case .call:
            return .call(try CallStmtParser().parse(&input))
        default:
            return .expr(try ExprParser().parse(&input))
        }
    }
}

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
struct OldWhileStmtParser: Parser {

    /// Parse a while statement.
    func parse(_ input: inout TokStream) throws -> ParsedWhileStmt {

        try ExactToken(kind: .whileTok).parse(&input)
        try ExactToken(kind: .lParen).parse(&input)
        let condition = try ConditionParser().parse(&input)
        try ExactToken(kind: .rParen).parse(&input)
        try ExactToken(kind: .lBrace).parse(&input)
        let body = try StmtListParser().parse(&input)
        try ExactToken(kind: .rBrace).parse(&input)

        return ParsedWhileStmt(condition: condition, body: body)
    }
}

struct WhileStmtParser: Parser {
    func parse(_ input: inout TokStream) throws -> ParsedWhileStmt {
        try ExactToken(kind: .whileTok).parse(&input)
        try ExactToken(kind: .lParen).parse(&input)
        let condition = try ConditionParser().parse(&input)
        try ExactToken(kind: .rParen).parse(&input)
        let body = try BlockParser().parse(&input)
        return ParsedWhileStmt(condition: condition, body: body)
    }
}

struct BlockParser: Parser {
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
