//
//  ParseProgram.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 4 August 2026.
//  Last changed on 5 August 2026.
//

import Foundation

/// Generaled source for a DeadEndsprogram file. It can be
/// a file (URL) or string.
private struct ProgramSource {

    let defns: [ParsedDefn]
    let sourceURL: URL?
    let baseURL: URL?
}

/// Allow sources to have three states -- has URL, does not have URL, does not exist.
private struct DefnSource {
    let url: URL?
}

/// Parse the definitions from a file with a DeadEnds program.
func parseDefinitions(fileURL: URL) throws -> [ParsedDefn] {

    let source = try String(contentsOf: fileURL, encoding: .utf8)
    return try parseDefinitions(source: source)
}

/// Parse the definitions from a string with a DeadEnds program.
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

/// Normalize smart quotes.
public func normalizedSource(_ text: String) -> String {
    text
        .replacingOccurrences(of: "“", with: "\"")
        .replacingOccurrences(of: "”", with: "\"")
        .replacingOccurrences(of: "‘", with: "'")
        .replacingOccurrences(of: "’", with: "'")
}

/// Parse a full (using includes) program starting from a URL.
public func parseFullProgram(fileURL: URL) throws -> ParsedProgram {

    let fileURL = fileURL.standardizedFileURL
    let defns = try parseDefinitions(fileURL: fileURL)

    let source = ProgramSource(defns: defns, sourceURL: fileURL,
        baseURL: fileURL.deletingLastPathComponent())
    return try assembleProgram(from: source)
}

/// Parse a full (using includes) program starting from a string.
public func parseFullProgram(source: String, sourceURL: URL?,
                             baseURL: URL?) throws -> ParsedProgram {

    let defns = try parseDefinitions(source: source)
    let source = ProgramSource(defns: defns, sourceURL: sourceURL, baseURL: baseURL)
    return try assembleProgram(from: source)
}

/// Overall method that parses a full program into a ParsedProgram object.
/// It starts with an initial source whose definitions have been determined.
private func assembleProgram(from source: ProgramSource) throws -> ParsedProgram {

    var pendingSources: [ProgramSource] = [source]
    var parsedURLs: Set<URL> = []
    var parsedDefns: [ParsedDefn] = []
    var procSources: [String: DefnSource] = [:]
    var funcSources: [String: DefnSource] = [:]
    var globalSources: [String: DefnSource] = [:]

    if let initialURL = source.sourceURL { // Put first URL on the queue.
        parsedURLs.insert(initialURL.standardizedFileURL)
    }
    while !pendingSources.isEmpty {

        let source = pendingSources.removeFirst()
        for defn in source.defns { // Definitions are already computed.

            switch defn {
            case .procDefn:
                try addDefn(defn, sourceURL: source.sourceURL, sources: &procSources,
                    defns: &parsedDefns)
            case .funcDefn:
                try addDefn(defn, sourceURL: source.sourceURL, sources: &funcSources,
                    defns: &parsedDefns)
            case .global:
                try addDefn(defn, sourceURL: source.sourceURL, sources: &globalSources,
                    defns: &parsedDefns)
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
                guard parsedURLs.insert(fileURL).inserted else {
                    continue
                }
                let includedDefinitions = try parseDefinitions(fileURL: fileURL)
                pendingSources.append(
                    ProgramSource(
                        defns: includedDefinitions,
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
        parsedDefns,
        procURLs: procURLs,
        funcURLs: funcURLs
    )
}

/// Add a definition to a program's parsed definitions and adds an entry to
/// specify the URL the definition came from.
private func addDefn(_ defn: ParsedDefn, sourceURL: URL?,
    sources: inout [String: DefnSource], defns: inout [ParsedDefn]) throws {

    if let prevSource = sources[defn.name] {
        let first = prevSource.url?.path ?? "the editor"
        let second = sourceURL?.path ?? "the editor"
        throw ParseError("\(defn.name) defined in both \(first) and \(second)",
            line: defn.line)
    }
    sources[defn.name] = DefnSource(url: sourceURL)
    defns.append(defn)
}
