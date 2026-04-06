//
//  Parser.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 5 April 2026.
//  Last changed on 6 April 2026.
//

//
//  ParsingTest.swift
//

import Foundation
import Parsing

// ------------------------------------------------------------
// Temporary parsed forms for early testing
// ------------------------------------------------------------

enum ParsedExpr: Equatable, CustomStringConvertible {
    case identifier(String)
    case intConst(Int)
    case floatConst(Double)
    case stringConst(String)
    case funcCall(String, [ParsedExpr])

    var description: String {
        switch self {
        case .identifier(let s):         return "id(\(s))"
        case .intConst(let i):           return "int(\(i))"
        case .floatConst(let f):         return "float(\(f))"
        case .stringConst(let s):        return "str(\(String(reflecting: s)))"
        case .funcCall(let name, let a): return "call(\(name), \(a))"
        }
    }
}

struct ParsedCallStmt: Equatable, CustomStringConvertible {
    let name: String
    let args: [ParsedExpr]

    var description: String {
        "CALL \(name)(\(args.map(\.description).joined(separator: ", ")))"
    }
}

// ------------------------------------------------------------
// Tiny token-level parser primitives
// ------------------------------------------------------------

public typealias TokStream = ArraySlice<Token>

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

struct IdentifierToken: Parser {
    func parse(_ input: inout TokStream) throws -> String {
        guard let tok = input.first else { throw DeadEndsParseError() }
        guard case .identifier(let name) = tok.kind else { throw DeadEndsParseError() }
        input.removeFirst()
        return name
    }
}

struct IntConstToken: Parser {
    func parse(_ input: inout TokStream) throws -> Int {
        guard let tok = input.first else { throw DeadEndsParseError() }
        guard case .intConst(let value) = tok.kind else { throw DeadEndsParseError() }
        input.removeFirst()
        return value
    }
}

struct FloatConstToken: Parser {
    func parse(_ input: inout TokStream) throws -> Double {
        guard let tok = input.first else { throw DeadEndsParseError() }
        guard case .floatConst(let value) = tok.kind else { throw DeadEndsParseError() }
        input.removeFirst()
        return value
    }
}

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

// ------------------------------------------------------------
// Expression parser
// ------------------------------------------------------------

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

    private func parseFunctionCall(_ input: inout TokStream) throws -> ParsedExpr {
        let name = try IdentifierToken().parse(&input)
        try ExactToken(kind: .lParen).parse(&input)
        let args = try ExprListOptionalParser().parse(&input)
        try ExactToken(kind: .rParen).parse(&input)
        return .funcCall(name, args)
    }
}

// ------------------------------------------------------------
// Expression list parsers
// ------------------------------------------------------------

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

// ------------------------------------------------------------
// CALL statement parser
// ------------------------------------------------------------

struct CallStmtParser: Parser {
    func parse(_ input: inout TokStream) throws -> ParsedCallStmt {
        try ExactToken(kind: .call).parse(&input)
        let name = try IdentifierToken().parse(&input)
        try ExactToken(kind: .lParen).parse(&input)
        let args = try ExprListOptionalParser().parse(&input)
        try ExactToken(kind: .rParen).parse(&input)
        return ParsedCallStmt(name: name, args: args)
    }
}

