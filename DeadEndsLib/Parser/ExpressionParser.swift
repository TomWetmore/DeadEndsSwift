//
//  ExpressionParser.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 6 April 2026.
//  Last changed on 25 April 2026.
//

import Foundation
import Parsing

/// Conditional expression parser.
struct ConditionParser: Parser {

    /// Parse a conditional expression.
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

/// Expression list parser.
struct ExprListParser: Parser {
    func parse(_ input: inout TokStream) throws -> [ParsedExpr] {
        var result: [ParsedExpr] = []
        result.append(try ExprParser().parse(&input))

        while true {
            let saved = input
            if (try? ExactToken(kind: .comma).parse(&input)) != nil {
                result.append(try ExprParser().parse(&input))
            } else {
                input = saved
                break
            }
        }
        return result
    }
}

/// Optional expression list parser.
struct ExprListOptionalParser: Parser {
    func parse(_ input: inout TokStream) throws -> [ParsedExpr] {
        let saved = input
        if let exprs = try? ExprListParser().parse(&input) {
            return exprs
        }
        input = saved
        return []
    }
}

/// Expression parser.
struct ExprParser: Parser {

    /// Parse an expression.
    func parse(_ input: inout TokStream) throws -> ParsedExpr {

        let line = input.first?.line ?? 0
        let saved = input
        // Try function call first because it begins with an identifier.
        if let expr = try? parseFunctionCall(&input) {
            return expr
        }
        input = saved

        if let name = try? IdentifierToken().parse(&input) {
            return ParsedExpr(kind: .identifier(name), line: line)
        }
        if let i = try? IntConstToken().parse(&input) {
            return ParsedExpr(kind: .integerConstant(i), line: line)
        }
        if let f = try? FloatConstToken().parse(&input) {
            return ParsedExpr(kind: .doubleConstant(f), line: line)
        }
        if let s = try? StringConstToken().parse(&input) {
            return ParsedExpr(kind: .stringConstant(s), line: line)
        }
        throw ParseError.syntax("expected expression start", line: line)
    }

    /// Function call parser.
    private func parseFunctionCall(_ input: inout TokStream) throws -> ParsedExpr {

        let line = input.first?.line ?? 0
        let name = try IdentifierToken().parse(&input)

        try ExactToken(kind: .lParen).parse(&input)
        let args = try ExprListOptionalParser().parse(&input)
        try ExactToken(kind: .rParen).parse(&input)
        return ParsedExpr(kind: .functionCall(name, args), line: line)
    }
}

public typealias TokStream = ArraySlice<Token>

/// Exact token parser.
struct ExactToken: Parser {

    let kind: TokenKind

    func parse(_ input: inout TokStream) throws {
        
        let line = input.first?.line ?? 0

        guard let tok = input.first else {
            throw ParseError.syntax("expected \(kind)", line: line)
        }
        guard tok.kind == kind else {
            throw ParseError.syntax("expected \(kind)", line: line)
        }
        input.removeFirst()
    }
}

/// Identifier parser.
struct IdentifierToken: Parser {

    func parse(_ input: inout TokStream) throws -> String {

        let line = input.first?.line ?? 0
        
        guard let tok = input.first else {
            throw ParseError.syntax("expected identifier", line: line)
        }
        guard case .identifier(let name) = tok.kind else {
            throw ParseError.syntax("expected identifier", line: line)
        }
        input.removeFirst()
        return name
    }
}

/// Integer parser.
struct IntConstToken: Parser {

    func parse(_ input: inout TokStream) throws -> Int {

        let line = input.first?.line ?? 0

        guard let tok = input.first else {
            throw ParseError.syntax("expected integer", line: line)
        }
        guard case .intConst(let value) = tok.kind else {
            throw ParseError.syntax("expected integer", line: line) }
        input.removeFirst()
        return value
    }
}

/// Floating point parser.
struct FloatConstToken: Parser {

    func parse(_ input: inout TokStream) throws -> Double {

        let line = input.first?.line ?? 0

        guard let tok = input.first else {
            throw ParseError.syntax("expected float", line: line)
        }
        guard case .floatConst(let value) = tok.kind else {
            throw ParseError.syntax("expected float", line: line) }
        input.removeFirst()
        return value
    }
}

/// String constant parser.
struct StringConstToken: Parser {

    func parse(_ input: inout TokStream) throws -> String {

        let line = input.first?.line ?? 0
        guard let tok = input.first else {
            throw ParseError.syntax("expected string", line: line)
        }
        guard case .stringConst(let value) = tok.kind else {
            throw ParseError.syntax("expected string", line: line)
        }
        input.removeFirst()
        return value
    }
}

public enum ParseError: Error, CustomStringConvertible {

    case syntax(_ message: String, line: Int)

    public var description: String {
        switch self {
        case .syntax(let message, let line):
            return "line \(line): \(message)"
        }
    }
}









