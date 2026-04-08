//
//  ProcFuncParser.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 7 April 2026.
//  Last changed on 7 April 2026.
//

import Foundation
import Parsing

struct ParsedProcDef: Equatable, CustomStringConvertible {
    let name: String
    let params: [String]
    let body: [ParsedStmt]

    var description: String {
        "PROC \(name)(\(params.joined(separator: ", "))) \(body)"
    }
}

struct ParsedFuncDef: Equatable, CustomStringConvertible {
    let name: String
    let params: [String]
    let body: [ParsedStmt]

    var description: String {
        "FUNC \(name)(\(params.joined(separator: ", "))) \(body)"
    }
}

struct ParsedGlobalDef: Equatable, CustomStringConvertible {
    let name: String

    var description: String {
        "GLOBAL(\(name))"
    }
}

enum ParsedDefn: Equatable, CustomStringConvertible {
    case proc(ParsedProcDef)
    case funcDef(ParsedFuncDef)
    case global(ParsedGlobalDef)

    var description: String {
        switch self {
        case .proc(let p): return p.description
        case .funcDef(let f): return f.description
        case .global(let g): return g.description
        }
    }
}

struct ParsedProgram: Equatable, CustomStringConvertible {
    let defns: [ParsedDefn]

    var description: String {
        defns.map(\.description).joined(separator: "\n")
    }
}

struct ParsedBreakStmt: Equatable, CustomStringConvertible {
    var description: String { "BREAK()" }
}

struct ParsedContinueStmt: Equatable, CustomStringConvertible {
    var description: String { "CONTINUE()" }
}

struct ParsedReturnStmt: Equatable, CustomStringConvertible {
    let values: [ParsedExpr]

    var description: String {
        "RETURN(\(values))"
    }
}

struct BreakStmtParser: Parser {
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

struct ReturnStmtParser: Parser {
    func parse(_ input: inout TokStream) throws -> ParsedReturnStmt {
        try ExactToken(kind: .returnTok).parse(&input)
        try ExactToken(kind: .lParen).parse(&input)
        let values = try ExprListOptionalParser().parse(&input)
        try ExactToken(kind: .rParen).parse(&input)
        return ParsedReturnStmt(values: values)
    }
}

struct IdentifierListParser: Parser {
    func parse(_ input: inout TokStream) throws -> [String] {
        var result: [String] = []
        result.append(try IdentifierToken().parse(&input))

        while true {
            let saved = input
            if (try? ExactToken(kind: .comma).parse(&input)) != nil {
                result.append(try IdentifierToken().parse(&input))
            } else {
                input = saved
                break
            }
        }

        return result
    }
}

struct IdentifierListOptionalParser: Parser {
    func parse(_ input: inout TokStream) throws -> [String] {
        let saved = input
        if let ids = try? IdentifierListParser().parse(&input) {
            return ids
        }
        input = saved
        return []
    }
}

struct ProcDefParser: Parser {
    func parse(_ input: inout TokStream) throws -> ParsedProcDef {
        try ExactToken(kind: .proc).parse(&input)
        let name = try IdentifierToken().parse(&input)
        try ExactToken(kind: .lParen).parse(&input)
        let params = try IdentifierListOptionalParser().parse(&input)
        try ExactToken(kind: .rParen).parse(&input)
        let body = try BlockParser().parse(&input)

        return ParsedProcDef(name: name, params: params, body: body)
    }
}

struct FuncDefParser: Parser {
    func parse(_ input: inout TokStream) throws -> ParsedFuncDef {
        try ExactToken(kind: .funcTok).parse(&input)
        let name = try IdentifierToken().parse(&input)
        try ExactToken(kind: .lParen).parse(&input)
        let params = try IdentifierListOptionalParser().parse(&input)
        try ExactToken(kind: .rParen).parse(&input)
        let body = try BlockParser().parse(&input)

        return ParsedFuncDef(name: name, params: params, body: body)
    }
}

struct GlobalDefParser: Parser {
    func parse(_ input: inout TokStream) throws -> ParsedGlobalDef {
        let name = try IdentifierToken().parse(&input)
        guard name == "global" else {
            throw DeadEndsParseError.generic
        }
        try ExactToken(kind: .lParen).parse(&input)
        let globalName = try IdentifierToken().parse(&input)
        try ExactToken(kind: .rParen).parse(&input)
        return ParsedGlobalDef(name: globalName)
    }
}

struct DefnParser: Parser {
    func parse(_ input: inout TokStream) throws -> ParsedDefn {
        guard let tok = input.first else {
            throw DeadEndsParseError()
        }

        switch tok.kind {
        case .proc:
            return .proc(try ProcDefParser().parse(&input))
        case .funcTok:
            return .funcDef(try FuncDefParser().parse(&input))
        case .identifier("global"):
            return .global(try GlobalDefParser().parse(&input))
        default:
            throw DeadEndsParseError.generic
        }
    }
}

/// Program parser.
struct ProgramParser: Parser {

    /// Parse a full program.
    func parse(_ input: inout TokStream) throws -> ParsedProgram {
        var defns: [ParsedDefn] = []

        while let tok = input.first, tok.kind != .eof {
            defns.append(try DefnParser().parse(&input))
        }
        return ParsedProgram(defns: defns)
    }
}
