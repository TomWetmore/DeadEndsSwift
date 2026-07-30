//
//  ProgramParser.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 8 April 2026.
//  Last changed on 29 July 2026.
//

import Foundation
import Parsing

/// Program parser. Currently part of the public API. It might be a good idea
/// to provide another public access that leaves this not public. Note we also
/// had to had a public init because of the current design.
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

    /// Parse a definition using one of three definition parsers.
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

struct IncludeDefParser: Parser {

    /// Parse an include definition.
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
public func parseFullProgram(fileURL: URL) throws -> ParsedProgram {

    var pendingFiles: [URL] = [fileURL.standardizedFileURL]
    var parsedFiles: Set<URL> = []

    // Map definitions to their files.
    var procURLs: [String: URL] = [:]
    var funcURLs: [String: URL] = [:]
    var globalURLs: [String: URL] = [:]

    var definitions: [ParsedDefn] = []

    while !pendingFiles.isEmpty {

        let fileURL = pendingFiles.removeFirst()
        print("PARSING: \(fileURL)") // DEBUG.
        guard parsedFiles.insert(fileURL).inserted else { continue }

        let tokens = try tokensFromURL(fileURL)
        var tokStream = TokStream(tokens)
        let defns = try ProgramParser().parse(&tokStream)

        for defn in defns {
            switch defn {

            case .procDefn(let procDefn):
                let name = procDefn.name
                guard procURLs[name] == nil else {
                    let message = "proc \(name) defined in \(procURLs[name]!) and \(fileURL)"
                    throw ParseError(message, line: procDefn.line)
                }
                procURLs[name] = fileURL
                definitions.append(defn)

            case .funcDefn(let funcDefn):
                let name = funcDefn.name
                guard funcURLs[name] == nil else {
                    let message = "func \(name) defined in \(funcURLs[name]!) and \(fileURL)"
                    throw ParseError(message, line: funcDefn.line)
                }
                funcURLs[funcDefn.name] = fileURL
                definitions.append(defn)

            case .global(let globalDefn):
                let name = globalDefn.name
                guard globalURLs[name] == nil else {
                    let message = "global \(name) defined in \(globalURLs[name]!) and \(fileURL)"
                    throw ParseError(message, line: globalDefn.line)
                }
                globalURLs[globalDefn.name] = fileURL
                definitions.append(defn)

            case .include(let includeDefn):
                let includeURL = fileURL
                    .deletingLastPathComponent()
                    .appendingPathComponent(includeDefn.name)
                    .standardizedFileURL

                pendingFiles.append(includeURL)
            }
        }
    }

    return ParsedProgram(definitions, procURLs: procURLs, funcURLs: funcURLs)
}

/// Get the sequence of tokens from a file URL.
func tokensFromURL(_ url: URL) throws -> [Token] {

    var source = try String(contentsOf: url, encoding: .utf8)
    source = normalizedSource(source)
    var lexer = Lexer(source: source)
    let tokens = lexer.tokenize()
    guard tokens.last?.kind == .eof else {
        throw FrontEndError.missingEOF
    }
    return tokens
}

/// Required because TextEditor uses smart quotes that are hard to turn off.
public func normalizedSource(_ text: String) -> String {
    text
        .replacingOccurrences(of: "“", with: "\"")
        .replacingOccurrences(of: "”", with: "\"")
        .replacingOccurrences(of: "‘", with: "'")
        .replacingOccurrences(of: "’", with: "'")
}
