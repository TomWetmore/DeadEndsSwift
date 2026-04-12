//
//  StatementParser.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on8 April 2026.
//  Last changed on 8 April 2026.
//

import Foundation
import Parsing


/// Block parser.
struct BlockParser: Parser {

    /// Parse a statement block.
    func parse(_ input: inout TokStream) throws -> [ParsedStatement] {

        try ExactToken(kind: .lBrace).parse(&input)
        let stmts = try StmtListParser().parse(&input)
        try ExactToken(kind: .rBrace).parse(&input)
        return stmts
    }
}

/// Statement list parser.
struct StmtListParser: Parser {

    /// Parse a statement list.
    func parse(_ input: inout TokStream) throws -> [ParsedStatement] {

        var result: [ParsedStatement] = []

        while let tok = input.first, tok.kind != .rBrace, tok.kind != .eof {
            result.append(try StmtParser().parse(&input))
        }
        return result
    }
}

/// Statement parser.
struct StmtParser: Parser {

    /// Parse a statement.
    func parse(_ input: inout TokStream) throws -> ParsedStatement {

        guard let tok = input.first else {
            throw DeadEndsParseError()
        }
        switch tok.kind {
        case .whileTok:
            return .whileStatement(try WhileStmtParser().parse(&input))
        case .ifTok:
            return .ifStatement(try IfStmtParser().parse(&input))
        case .call:
            return .callStatement(try CallStmtParser().parse(&input))
        case .returnTok:
            return .returnStatement(try ReturnStmtParser().parse(&input))
        case .breakTok:
            return .breakStatement(try BreakStmtParser().parse(&input))
        case .continueTok:
            return .continueStatement(try ContinueStmtParser().parse(&input))
        default:
            return .expressionStatement(try ExprParser().parse(&input))
        }
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

/// If statement parser.
struct IfStmtParser: Parser {

    /// Parse an if statement.
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

    /// Parse an else-if clause/
    private func parseElseIf(_ input: inout TokStream) throws -> ParsedElseIf {

        try ExactToken(kind: .elsif).parse(&input)
        try ExactToken(kind: .lParen).parse(&input)
        let condition = try ConditionParser().parse(&input)
        try ExactToken(kind: .rParen).parse(&input)

        let body = try BlockParser().parse(&input)
        return ParsedElseIf(condition: condition, body: body)
    }

    /// Parse an else clause.
    private func parseElse(_ input: inout TokStream) throws -> [ParsedStatement] {
        try ExactToken(kind: .elseTok).parse(&input)
        return try BlockParser().parse(&input)
    }
}

/// Call statement parser.
struct CallStmtParser: Parser {

    /// Parse a call statement.
    func parse(_ input: inout TokStream) throws -> ParsedCallStatement {

        try ExactToken(kind: .call).parse(&input)
        let name = try IdentifierToken().parse(&input)
        try ExactToken(kind: .lParen).parse(&input)
        let args = try ExprListOptionalParser().parse(&input)
        try ExactToken(kind: .rParen).parse(&input)
        return ParsedCallStatement(name: name, args: args)
    }
}

/// Return statement parser.
struct ReturnStmtParser: Parser {

    /// Parse a return statement.
    func parse(_ input: inout TokStream) throws -> ParsedReturnStmt {
        try ExactToken(kind: .returnTok).parse(&input)
        try ExactToken(kind: .lParen).parse(&input)
        let values = try ExprListOptionalParser().parse(&input)
        try ExactToken(kind: .rParen).parse(&input)
        return ParsedReturnStmt(values: values)
    }
}

/// Break statement parser.
struct BreakStmtParser: Parser {

    /// Parse a break statement.
    func parse(_ input: inout TokStream) throws -> ParsedBreakStmt {
        try ExactToken(kind: .breakTok).parse(&input)
        try ExactToken(kind: .lParen).parse(&input)
        try ExactToken(kind: .rParen).parse(&input)
        return ParsedBreakStmt()
    }
}

struct ContinueStmtParser: Parser {
    func parse(_ input: inout TokStream) throws -> ParsedContinueStmt {
        try ExactToken(kind: .continueTok).parse(&input)
        try ExactToken(kind: .lParen).parse(&input)
        try ExactToken(kind: .rParen).parse(&input)
        return ParsedContinueStmt()
    }
}


