//
//  GedcomLineParser.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 15 October 2026.
//  Last changed on 15 October 2026.
//

import Foundation

/// Result returned by parseLine; on success holds Gedcom fields; on failure holds error message.
///
enum ParseResult {

    case success(lev: Int, key: String?, tag: String, val: String?)
    case failure(errmsg: String)
}

/// Lexer for Gedcom lines; extracts lev, key, tag and val; returns them in a parse result.
///
func parseLine(from line: String) -> ParseResult {

    let trim = line.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trim.isEmpty else { return .failure(errmsg: "Empty string") }
    guard trim.count <= 255 else { return .failure(errmsg: "Gedcom line is too long") }
    var index = trim.startIndex

    /// Local function to skip white space.
    func skipWhiteSpace() {
        while index < trim.endIndex, trim[index].isWhitespace {
            index = trim.index(after: index)
        }
    }

    // Level.
    skipWhiteSpace()
    guard index < trim.endIndex, trim[index].isNumber else {
        return .failure(errmsg: "Line does not begin with level")
    }
    var levString = ""
    while index < trim.endIndex, trim[index].isNumber {
        levString.append(trim[index])
        index = trim.index(after: index)
    }
    guard let lev = Int(levString) else {
        return .failure(errmsg: "Invalid level")
    }

    // Key if present.
    skipWhiteSpace()
    if index >= trim.endIndex {
        return .failure(errmsg: "Gedcom line is incomplete")
    }
    var key: String? = nil
    if trim[index] == "@" {
        let keyStart = index
        index = trim.index(after: index)
        guard index < trim.endIndex, trim[index] != "@"
        else { return .failure(errmsg: "Illegal key (@@)") }
        while index < trim.endIndex, trim[index] != "@" {
            index = trim.index(after: index)
        }
        guard index < trim.endIndex else {
            return .failure(errmsg: "Gedcom line is incomplete")
        }
        index = trim.index(after: index) // Skip closing '@'
        guard index < trim.endIndex, trim[index].isWhitespace else {
            return .failure(errmsg: "There must be a space between the key and tag")
        }
        key = String(trim[keyStart..<index])
        index = trim.index(after: index) // Skip the space
    }
    skipWhiteSpace()
    guard index < trim.endIndex else {
        return .failure(errmsg: "The line is incomplete")
    }

    // Tag.
    let tagStart = index
    while index < trim.endIndex, !trim[index].isWhitespace {
        index = trim.index(after: index)
    }
    let tag = String(trim[tagStart..<index])

    // Value.
    skipWhiteSpace()
    let val = index < trim.endIndex ? String(trim[index...]) : nil

    return .success(lev: lev, key: key, tag: tag, val: val)
}
