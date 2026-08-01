//
//  ProgramParser.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 8 April 2026.
//  Last changed on 1 August 2026.
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

/// Include definition parser.
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

/// Identifier list parser.
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

/// Optional identifier list parser.
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

/// Get the sequence of tokens from a file URL.
func tokensFromURL(_ url: URL) throws -> [Token] {

    var source = try String(contentsOf: url, encoding: .utf8)
    source = normalizedSource(source)
    var lexer = Lexer(source: source)
    let tokens = lexer.tokenize()
    guard tokens.last?.kind == .eof else {
        let message = "file does not end with an EOF token"
        throw ParseError(message, line: 0)
    }
    return tokens
}

/// Parse the definitions from a file holding a DeadEnds program.
func parseDefinitions(fileURL: URL) throws -> [ParsedDefn] {

    let tokens = try tokensFromURL(fileURL)
    var input = TokStream(tokens)

    let definitions = try ProgramParser().parse(&input)

    try ExactToken(kind: .eof).parse(&input)
    guard input.isEmpty else {
        let message = "parse did not consume all input"
        throw ParseError(message, line: input.first?.line ?? 0)
    }

    return definitions
}

/// Parse definitions from a text buffer holding a DeadEnds program.
func parseDefinitions(source: String) throws -> [ParsedDefn] {

    var lexer = Lexer(source: normalizedSource(source))
    let tokens = lexer.tokenize()

    guard tokens.last?.kind == .eof else {
        let message = "source does not end with an end of file"
        throw ParseError(message, line: 0)
    }
    var input = TokStream(tokens)
    let definitions = try ProgramParser().parse(&input)
    try ExactToken(kind: .eof).parse(&input)

    guard input.isEmpty else {
        throw ParseError(
            "parse did not consume all input",
            line: input.first?.line ?? 0
        )
    }
    return definitions
}

/// Required because TextEditor uses smart quotes that are hard to turn off.
public func normalizedSource(_ text: String) -> String {
    text
        .replacingOccurrences(of: "“", with: "\"")
        .replacingOccurrences(of: "”", with: "\"")
        .replacingOccurrences(of: "‘", with: "'")
        .replacingOccurrences(of: "’", with: "'")
}

/// Generalization of a source for a program file. It can start
/// as a file or a text buffer.
private struct ProgramSource {

    let definitions: [ParsedDefn]
    let sourceURL: URL?
    let baseURL: URL?
}

private struct DefnSource {
    let url: URL?
}

/// Parse a full (using includes) program starting from a fileURL.
public func parseFullProgram(fileURL: URL) throws -> ParsedProgram {

    let fileURL = fileURL.standardizedFileURL
    let defns = try parseDefinitions(fileURL: fileURL)
    //print("THERE ARE \(defns.count) DEFINIIONS")

    let source = ProgramSource(
        definitions: defns,
        sourceURL: fileURL,
        baseURL: fileURL.deletingLastPathComponent()
    )
    return try assembleProgram(with: source)
}

/// Parse a full (using includes) program starting from a text buffer.
public func parseFullProgram(source: String, sourceURL: URL?, baseURL: URL?) throws -> ParsedProgram {

    let definitions = try parseDefinitions(source: source)
    let source = ProgramSource(
        definitions: definitions,
        sourceURL: sourceURL,
        baseURL: baseURL
    )
    return try assembleProgram(with: source)
}

/// Overall mechanism for parsing a full program into a ParsedProgram object.
/// It starts with an initial source whose definitions have been determined.
private func assembleProgram(with initialSource: ProgramSource) throws -> ParsedProgram {

    var pendingSources: [ProgramSource] = [initialSource]
    var parsedFiles: Set<URL> = []

    var definitions: [ParsedDefn] = []

    //let globalURLs: [String: URL?] = [:] // TODO: MUST BE CHANGED.

    var procSources: [String: DefnSource] = [:]
    var funcSources: [String: DefnSource] = [:]
    var globalSources: [String: DefnSource] = [:]

    if let initialURL = initialSource.sourceURL {
        parsedFiles.insert(initialURL.standardizedFileURL)
    }

    while !pendingSources.isEmpty {
        // Get the next source to process.
        let source = pendingSources.removeFirst()

        // For each definition in the source (already computed).
        for defn in source.definitions {
            switch defn {

            case .procDefn(let procDefn):
                try addDefn(
                    defn,
                    name: procDefn.name,
                    line: procDefn.line,
                    sourceURL: source.sourceURL,
                    sources: &procSources,
                    definitions: &definitions
                )

            case .funcDefn(let funcDefn):
                try addDefn(
                    defn,
                    name: funcDefn.name,
                    line: funcDefn.line,
                    sourceURL: source.sourceURL,
                    sources: &funcSources,
                    definitions: &definitions
                )

            case .global(let globalDefn):
                try addDefn(
                    defn,
                    name: globalDefn.name,
                    line: globalDefn.line,
                    sourceURL: source.sourceURL,
                    sources: &globalSources,
                    definitions: &definitions
                )

            case .include(let includeDefn):
                guard let baseURL = source.baseURL else {
                    throw ParseError(
                        "cannot resolve include \"\(includeDefn.name)\" " +
                        "because the source has no include directory",
                        line: includeDefn.line
                    )
                }

                let fileURL = baseURL
                    .appendingPathComponent(includeDefn.name)
                    .standardizedFileURL

                guard parsedFiles.insert(fileURL).inserted else {
                    continue
                }
                let includedDefinitions = try parseDefinitions(fileURL: fileURL)

                pendingSources.append(
                    ProgramSource(
                        definitions: includedDefinitions,
                        sourceURL: fileURL,
                        baseURL: fileURL.deletingLastPathComponent()
                    )
                )
            }
        }
    }

    let procURLs = procSources.mapValues(\.url)
    let funcURLs = funcSources.mapValues(\.url)

    return ParsedProgram(
        definitions,
        procURLs: procURLs,
        funcURLs: funcURLs
    )
}

private func addDefn(_ definition: ParsedDefn, name: String, line: Int,
    sourceURL: URL?, sources: inout [String: DefnSource],
    definitions: inout [ParsedDefn]
) throws {

    if let previousSource = sources[name] {
        let first = previousSource.url?.path ?? "the editor"
        let second = sourceURL?.path ?? "the editor"

        throw ParseError("\(name) defined in both \(first) and \(second)", line: line)
    }
    sources[name] = DefnSource(url: sourceURL)
    definitions.append(definition)
}
