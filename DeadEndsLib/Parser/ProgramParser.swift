//
//  ProgramParser.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 8 April 2026.
//  Last changed on 5 August 2026.
//

import Foundation
import Parsing

/// Program parser. Currently part of the public API.
public struct ProgramParser: Parser {

    /// Parse a program. A program is a list of definitions.
    public func parse(_ input: inout TokStream) throws -> [ParsedDefn] {

        var defns: [ParsedDefn] = []
        while let tok = input.first, tok.kind != .eof {
            defns.append(try DefnParser().parse(&input))
        }
        return defns
    }

    public init() {}  // Currently part of the public API
}

/// Definition Parser.
struct DefnParser: Parser {

    /// Parse a definition using one of the definition parsers.
    func parse(_ input: inout TokStream) throws -> ParsedDefn {

        let line = input.first?.line ?? 0
        
        guard let tok = input.first else {
            throw ParseError("expecting a definition", line: line)
        }
        switch tok.kind {
        case .proc:
            return .procDefn(try ProcDefParser().parse(&input))
        case .funcTok:
            return .funcDefn(try FuncDefParser().parse(&input))
        case .identifier("global"):
            return .global(try GlobalDefParser().parse(&input))
        case .identifier("include"):
            return .include(try IncludeDefParser().parse(&input))
        default:
            throw ParseError("expecting a definiton", line: line)
        }
    }
}

/// Procedure definition parser.
struct ProcDefParser: Parser {

    /// Parse a procedure definition.
    func parse(_ input: inout TokStream) throws -> ParsedProcDefn {

        let line = input.first?.line ?? 0

        try ExactToken(kind: .proc).parse(&input)
        let name = try IdentifierToken().parse(&input)
        try ExactToken(kind: .lParen).parse(&input)
        let params = try IdentifierListOptionalParser().parse(&input)
        try ExactToken(kind: .rParen).parse(&input)
        let body = try BlockParser().parse(&input)

        return ParsedProcDefn(name: name, params: params, body: body, line: line)
    }
}

/// Function definition parser.
struct FuncDefParser: Parser {

    /// Parse a function definition.
    func parse(_ input: inout TokStream) throws -> ParsedFuncDefn {

        let line = input.first?.line ?? 0

        try ExactToken(kind: .funcTok).parse(&input)
        let name = try IdentifierToken().parse(&input)
        try ExactToken(kind: .lParen).parse(&input)
        let params = try IdentifierListOptionalParser().parse(&input)
        try ExactToken(kind: .rParen).parse(&input)
        let body = try BlockParser().parse(&input)

        return ParsedFuncDefn(name: name, params: params, body: body, line: line)
    }
}

/// Global definition parser.
struct GlobalDefParser: Parser {

    /// Parse a global definition.
    func parse(_ input: inout TokStream) throws -> ParsedGlobalDefn {

        let line = input.first?.line ?? 0

        let name = try IdentifierToken().parse(&input)
        guard name == "global" else {
            throw ParseError("expected \"global\"", line: line)
        }
        try ExactToken(kind: .lParen).parse(&input)
        let globalName = try IdentifierToken().parse(&input)
        try ExactToken(kind: .rParen).parse(&input)

        return ParsedGlobalDefn(name: globalName, line: line)
    }
}

/// Include statement parser.
struct IncludeDefParser: Parser {

    /// Parse an include statement.
    func parse(_ input: inout TokStream) throws -> ParsedIncludeDefn {

        let line = input.first?.line ?? 0

        let name = try IdentifierToken().parse(&input)
        guard name == "include" else {
            throw ParseError("expected \"include\"", line: line)
        }
        try ExactToken(kind: .lParen).parse(&input)
        let includeName = try StringConstToken().parse(&input)
        try ExactToken(kind: .rParen).parse(&input)

        return ParsedIncludeDefn(name: includeName, line: line)
    }
}

/// Identifier list parser.
struct IdentifierListParser: Parser {

    /// Parse a list of identifiers.
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

/// Optional identifier list parser.
struct IdentifierListOptionalParser: Parser {

    /// Parse an optional list of identifiers.
    func parse(_ input: inout TokStream) throws -> [String] {

        let saved = input
        if let ids = try? IdentifierListParser().parse(&input) {
            return ids
        }
        input = saved
        return []
    }
}
