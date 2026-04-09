//
//  ProgramParser.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 8 April 2026.
//  Last changed on 8 April 2026.
//

import Foundation
import Parsing

/// Program parser.
struct ProgramParser: Parser {
    
    /// Parse a program. A program is a list of definitions.
    func parse(_ input: inout TokStream) throws -> ParsedProgram {
        var defns: [ParsedDefn] = []
        
        while let tok = input.first, tok.kind != .eof {
            defns.append(try DefnParser().parse(&input))
        }
        return ParsedProgram(defns: defns)
    }
}

/// Definition Parser.
struct DefnParser: Parser {

    /// Parse a definition using one of three definition parsers.
    func parse(_ input: inout TokStream) throws -> ParsedDefn {
        guard let tok = input.first else {
            throw DeadEndsParseError()
        }

        switch tok.kind {
        case .proc:
            return .procDef(try ProcDefParser().parse(&input))
        case .funcTok:
            return .funcDef(try FuncDefParser().parse(&input))
        case .identifier("global"):
            return .global(try GlobalDefParser().parse(&input))
        default:
            throw DeadEndsParseError.generic
        }
    }
}

/// Procedure definition parser.
struct ProcDefParser: Parser {

    /// Parse a procedure definition.
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

/// Function definition parser.
struct FuncDefParser: Parser {

    /// Parse a function definition.
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

/// Global definition parser.
struct GlobalDefParser: Parser {

    /// Parse a global definition.
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




