//
//  IfWhileParser.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 6 April 2026.
//  Last changed on 8 April 2026.
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

public typealias TokStream = ArraySlice<Token>

/// Exact token parser.
struct ExactToken: Parser {
    let kind: TokenKind

    func parse(_ input: inout TokStream) throws {
        guard let tok = input.first else {
            throw DeadEndsParseError()
        }
        guard tok.kind == kind else {
            throw DeadEndsParseError()
        }
        input.removeFirst()
    }
}

/// Identifier parser.
struct IdentifierToken: Parser {
    func parse(_ input: inout TokStream) throws -> String {
        guard let tok = input.first else { throw DeadEndsParseError() }
        guard case .identifier(let name) = tok.kind else { throw DeadEndsParseError() }
        input.removeFirst()
        return name
    }
}

/// Integer parser.
struct IntConstToken: Parser {
    func parse(_ input: inout TokStream) throws -> Int {
        guard let tok = input.first else { throw DeadEndsParseError() }
        guard case .intConst(let value) = tok.kind else { throw DeadEndsParseError() }
        input.removeFirst()
        return value
    }
}

/// Floating point parser.
struct FloatConstToken: Parser {
    func parse(_ input: inout TokStream) throws -> Double {
        guard let tok = input.first else { throw DeadEndsParseError() }
        guard case .floatConst(let value) = tok.kind else { throw DeadEndsParseError() }
        input.removeFirst()
        return value
    }
}

/// String constant parser.
struct StringConstToken: Parser {
    func parse(_ input: inout TokStream) throws -> String {
        guard let tok = input.first else { throw DeadEndsParseError() }
        guard case .stringConst(let value) = tok.kind else { throw DeadEndsParseError() }
        input.removeFirst()
        return value
    }
}

enum DeadEndsParseError: Error, CustomStringConvertible {
    case generic

    init() { self = .generic }

    var description: String { "parse error" }
}

/// Expression parser.
struct ExprParser: Parser {


    func parse(_ input: inout TokStream) throws -> ParsedExpr {
        // Try function call first because it begins with an identifier.
        let saved = input
        if let expr = try? parseFunctionCall(&input) {
            return expr
        }
        input = saved

        if let name = try? IdentifierToken().parse(&input) {
            return .identifier(name)
        }
        if let i = try? IntConstToken().parse(&input) {
            return .intConst(i)
        }
        if let f = try? FloatConstToken().parse(&input) {
            return .floatConst(f)
        }
        if let s = try? StringConstToken().parse(&input) {
            return .stringConst(s)
        }
        throw DeadEndsParseError()
    }

    /// Function call parser.
    private func parseFunctionCall(_ input: inout TokStream) throws -> ParsedExpr {
        let name = try IdentifierToken().parse(&input)
        try ExactToken(kind: .lParen).parse(&input)
        let args = try ExprListOptionalParser().parse(&input)
        try ExactToken(kind: .rParen).parse(&input)
        return .funcCall(name, args)
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








