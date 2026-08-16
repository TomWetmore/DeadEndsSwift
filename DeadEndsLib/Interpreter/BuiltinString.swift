//
//  BuiltinString.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 12 May 2026.
//  Last changed on 14 August 2026.
//

import Foundation


extension Program {

    func bltinUpper(_ args: [ParsedExpr]) async throws -> ProgramValue {

        guard let string = try await evaluateStringOpt(args[0],
                                                       errMsg: "upper: arg must be a string")
        else { return .null }
        return .string(string.uppercased())
    }

    func bltinLower(_ args: [ParsedExpr]) async throws -> ProgramValue {

        guard let string = try await evaluateStringOpt(args[0],
                                                       errMsg: "lower: arg must be a string")
        else { return .null }
        return .string(string.lowercased())
    }

    func bltinCapitalize(_ args: [ParsedExpr]) async throws -> ProgramValue {
        
        guard let string = try await evaluateStringOpt(args[0],
                                                       errMsg: "capitalize: arg must be a string")
        else { return .null }
        return .string(string.capitalized)
    }

    func bltinWords(_ args: [ParsedExpr]) async throws -> ProgramValue {

        guard let strng = try await evaluateStringOpt(args[0],
                                                       errMsg: "words: arg must be a string")
        else { return .null }
        let words = strng.words().map { ProgramValue.string($0) }
        return .list(List(words))
    }

    func bltinTokens(_ args: [ParsedExpr]) async throws -> ProgramValue {

        guard let strng = try await evaluateStringOpt(args[0],
                                                       errMsg: "words: arg must be a string")
        else { return .null }
        let words = strng.tokens().map { ProgramValue.string($0) }
        return .list(List(words))
    }

    /// Compare two strings.
    /// strcmp(STRING, STRING) -> INT
    /// Returns -1, 0, or 1.
    func bltinStrcmp(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let value1 = try await evaluate(args[0])
        guard case let .string(str1) = value1 else {
            throw RuntimeError("strcmp: 1st arg must be a string", line: args[0].line)
        }
        let value2 = try await evaluate(args[1])
        guard case let .string(str2) = value2 else {
            throw RuntimeError("strcmp: second arg must be a string", line: args[1].line)
        }
        switch str1.compare(str2) {
        case .orderedAscending:
            return .integer(-1)
        case .orderedSame:
            return .integer(0)
        case .orderedDescending:
            return .integer(1)
        }
    }
}

extension String {

    /// Break a string into words, removing white space and punctionation.
    func words() -> [String] {

        var result: [String] = []
        var word = ""

        for char in self {
            if char.isLetter || char.isNumber {
                word.append(char)
            } else if !word.isEmpty {
                result.append(word)
                word = ""
            }
        }

        if !word.isEmpty {
            result.append(word)
        }

        return result
    }

    /// Break a string into tokens, keeping words and punctuation.
    func tokens() -> [String] {

        var result: [String] = []
        var word = ""

        for char in self {

            if char.isLetter || char.isNumber {
                word.append(char)
                continue
            }

            if !word.isEmpty {
                result.append(word)
                word = ""
            }

            if !char.isWhitespace {
                result.append(String(char))
            }
        }

        if !word.isEmpty {
            result.append(word)
        }

        return result
    }
}
