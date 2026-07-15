//
//  ProgramParser.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 8 April 2026.
//  Last changed on 18 May 2026.
//

import Foundation
import Parsing

/// Program parser. Currently part of the public API. It might be a good idea
/// to provide another public access that leaves this not public. Note we also
/// had to had a public init because of the current design.
public struct ProgramParser: Parser {

    /// Parse a program. A program is a list of definitions.
    public func parse(_ input: inout TokStream) throws -> ParsedProgram {

        var defns: [ParsedDefn] = []
        
        while let tok = input.first, tok.kind != .eof {
            defns.append(try DefnParser().parse(&input))
        }
        return ParsedProgram(defns: defns)
    }

    public init() {}  // Currently part of the public API
}

/// Definition Parser.
struct DefnParser: Parser {

    /// Parse a definition using one of three definition parsers.
    func parse(_ input: inout TokStream) throws -> ParsedDefn {

        let line = input.first?.line ?? 0

        guard let tok = input.first else {
            throw ParseError("expecting a definition", line: line)
        }
        switch tok.kind {
        case .proc:
            return .procDef(try ProcDefParser().parse(&input))
        case .funcTok:
            return .funcDef(try FuncDefParser().parse(&input))
        case .identifier("global"):
            return .global(try GlobalDefParser().parse(&input))
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

// Addition heading for the refactoring to include include.


//func parseFullProgram(fileName: String) throws -> ParsedProgram {
//
//    var pendingFiles: [String] = [fileName]
//    var nextFileIndex = 0
//
//    var defns: [ParsedDefn] = []
//
//    while nextFileIndex < pendingFiles.count {
//        let nextFile = pendingFiles[nextFileIndex]
//        nextFileIndex += 1
//
//        let fileDefns = try parseFile(fileName: nextFile)
//        defns.append(contentsOf: fileDefns)
//    }
//
//    return ParsedProgram(defns: defns)
//}

// Starting the refactoring needed to move to the include feature.

func parseFile(source: String) throws -> ParsedProgram {

    let normalized = normalizedSource(source)  // Temporary quote hack.
    var lexer = Lexer(source: normalized)
    let tokens = lexer.tokenize()
    guard tokens.last?.kind == .eof else {
        throw FrontEndError.missingEOF
    }
    var input = tokens[...]
    let program = try ProgramParser().parse(&input)

    if input.first?.kind == .eof {
        input.removeFirst()
    }
    guard input.isEmpty else {
        throw FrontEndError.parseDidNotConsumeAllInput(Array(input))
    }
    return program
}

/// Required because TextEditor uses smart quotes that are hard to turn off.
public func normalizedSource(_ text: String) -> String {
    text
        .replacingOccurrences(of: "“", with: "\"")
        .replacingOccurrences(of: "”", with: "\"")
        .replacingOccurrences(of: "‘", with: "'")
        .replacingOccurrences(of: "’", with: "'")
}
