//
//  Lexer.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 3 April 2026.
//  Last changed on 24 April 2026.
//

import Foundation

/// Lexer for the DeadEnds programming language.
public struct Lexer {

    let source: String
    var index: String.Index
    public var line: Int = 1

    public init(source: String) {
        self.source = source
        self.index = source.startIndex
//        for c in source {
//            print(c, c.unicodeScalars.first!.value)
//        }
    }
}

/// High level methods for overall tokenization.
extension Lexer {

    /// Tokenize the source into an array of tokens, including EOF.
    mutating public func tokenize() -> [Token] {
        var tokens: [Token] = []

        while true {
            let token = nextToken()
            tokens.append(token)
            if token.kind == .eof { break }
        }
        return tokens
    }

    /// Return the next token from the source.
    public mutating func nextToken() -> Token {
        let startLine = line

        skipWhiteSpaceAndComments()
        guard let c = peek()
        else { return Token(kind: .eof, line: startLine) }
        if c.isLetter { return lexIdentifierOrKeyword() }
        if c.isNumber || c == "-" || c == "." { return lexNumberOrMinus() }
        if c == "\"" || c == "“" { return lexString() }
        advance()
        switch c {
        case "(": return Token(kind: .lParen, line: startLine)
        case ")": return Token(kind: .rParen, line: startLine)
        case "{": return Token(kind: .lBrace, line: startLine)
        case "}": return Token(kind: .rBrace, line: startLine)
        case ",": return Token(kind: .comma, line: startLine)
        case "/": return Token(kind: .slash, line: startLine)
        default: return Token(kind: .unknown, line: startLine)
        }
    }
}

/// Low level index methods.
extension Lexer {

    /// Peek at the next character.
    private func peek() -> Character? {
        guard index < source.endIndex else { return nil }
        return source[index]
    }

    /// Advance one character.
    @discardableResult
    mutating private func advance() -> Character? {
        guard let c = peek() else { return nil }
        index = source.index(after: index)
        if c.isNewline { line += 1 }
        return c
    }

    /// Backup one character.
    mutating private func backup() {
        index = source.index(before: index)
        if peek() == "\n" { line -= 1 }
    }
}

/// Mid level source processing methods.
extension Lexer {

    /// Skip whitespace and comments.
    mutating private func skipWhiteSpaceAndComments() {
        while true {
            while let c = peek(), c.isWhitespace { advance() } // Skip whitespace.
            guard peek() == "/" else { return }  // If not at '/' return.

            advance()  // Pass the '/'.
            if peek() != "*" {  // Put the '/' back, return.
                backup()
                return
            }
            advance()  // Now in a comment.
            while let c = advance() {  // Scan to end of comment.
                if c == "*" && peek() == "/" {
                    advance()   // Consume the final '/'.
                    break
                }
            }
            if peek() == nil { return }  // Check for end of input, continue main loop.
        }
    }

    /// Lex an identifier or reserved word.
    mutating private func lexIdentifierOrKeyword() -> Token {
        let startLine = line
        var text = ""

        while let c = peek(), c.isLetter || c.isNumber || c == "_" {
            text.append(advance()!)
        }

        let kind = keywordKind(for: text) ?? .identifier(text)
        return Token(kind: kind, line: startLine)
    }

    /// Lex an integer or floating point literal. It can be positive or negative.
    mutating private func lexNumberOrMinus() -> Token {
        let startLine = line

        // Handle '-'.
        var isNegative = false
        if peek() == "-" {
            advance()
            if let n = peek(), !(n.isNumber || n == ".") {
                return Token(kind: .minus, line: startLine)
            }
            if peek() == nil {
                return Token(kind: .minus, line: startLine)
            }
            isNegative = true
        }

        // Current char is a digit or '.'
        var sawWholeDigit = false
        var intValue = 0

        // Integer part
        while let c = peek(), c.isNumber {
            sawWholeDigit = true
            if let d = c.wholeNumberValue {
                intValue = intValue * 10 + d
            }
            advance()
        }

        var sawFractionDigit = false
        var fracValue: Double = 0
        var fracDivisor: Double = 1
        var sawDecimalPoint = false

        // Fractional part
        if peek() == "." {
            sawDecimalPoint = true
            advance() // consume '.'

            while let c = peek(), c.isNumber {
                sawFractionDigit = true
                if let d = c.wholeNumberValue {
                    fracValue = fracValue * 10 + Double(d)
                    fracDivisor *= 10
                }
                advance()
            }
        }
        // No digits at all: either "." or "-."
        if !sawWholeDigit && !sawFractionDigit {
            if isNegative && sawDecimalPoint {
                backup()   // put back '.'
                return Token(kind: .minus, line: startLine)
            } else {
                return Token(kind: .period, line: startLine)
            }
        }
        if !sawDecimalPoint {
            let value = isNegative ? -intValue : intValue
            return Token(kind: .intConst(value), line: startLine)
        } else {
            let whole = Double(intValue)
            let value = whole + (fracValue / fracDivisor)
            let final = isNegative ? -value : value
            return Token(kind: .floatConst(final), line: startLine)
        }
    }

    /// Lex a string constant.
    mutating private func lexString() -> Token {
        let startLine = line

        advance()  // Consume opening quote.
        var text = ""

        while true {
            guard let c = advance() else {
                return Token(kind: .stringConst(text), line: startLine)  // EOF.
            }
            if c == "\""  || c == "”"{  // Closing quote.
                return Token(kind: .stringConst(text), line: startLine)
            }
            if c == "\\" { // Escape sequence.
                guard let esc = advance() else {
                    // EOF after backslash: return what we have.
                    return Token(kind: .stringConst(text), line: startLine)
                }
                switch esc {
                case "n":  text.append("\n")
                case "t":  text.append("\t")
                case "v":  text.append("\u{000B}")   // vertical tab
                case "r":  text.append("\r")
                case "b":  text.append("\u{0008}")   // backspace
                case "f":  text.append("\u{000C}")   // form feed
                case "\"": text.append("\"")
                case "\\": text.append("\\")
                default:   text.append(esc)
                }
            } else {
                // Ordinary character
                text.append(c)
            }
        }
    }
}

/// Enumeration for kinds of tokens.
public enum TokenKind: Equatable {

    case identifier(String)
    case intConst(Int)
    case floatConst(Double)
    case stringConst(String)

    case proc
    case funcTok
    case children
    case spouses
    case ifTok
    case elseTok
    case elsif
    case families
    case whileTok
    case call
    case forindiset
    case forindi
    case fornotes
    case traverse
    case fornodes
    case forlist
    case forfam
    case forsour
    case foreven
    case forothr
    case breakTok
    case continueTok
    case returnTok
    case fathers
    case mothers
    case parents

    case lParen
    case rParen
    case lBrace
    case rBrace
    case comma
    case slash
    case minus
    case period
    case unknown

    case eof
}

/// Implement equatable for tokens.
public struct Token: Equatable {
    public let kind: TokenKind
    public let line: Int
}

/// Implement custom string convertible for tokens.
extension Token: CustomStringConvertible {
    public var description: String {
        "Token(\(line), \(kind))"
    }
}

/// Return token kind of a string.
func keywordKind(for word: String) -> TokenKind? {
    switch word {
    case "break": return .breakTok
    case "call": return .call
    case "children": return .children
    case "continue": return .continueTok
    case "else": return .elseTok
    case "elsif": return .elsif
    case "families": return .families
    case "fathers": return .fathers
    case "foreven": return .foreven
    case "forfam": return .forfam
    case "forindiset": return .forindiset
    case "forindi": return .forindi
    case "forlist": return .forlist
    case "fornodes": return .fornodes
    case "fornotes": return .fornotes
    case "forothr": return .forothr
    case "forsour": return .forsour
    case "func": return .funcTok
    case "if": return .ifTok
    case "mothers": return .mothers
    case "Parents": return .parents
    case "proc": return .proc
    case "return": return .returnTok
    case "spouses": return .spouses
    case "traverse": return .traverse
    case "while": return .whileTok
    default: return nil
    }
}


/// Implement custom string convertible for token kinds.
extension TokenKind: CustomStringConvertible {
    public var description: String {
        switch self {
        case .identifier(let s):  return "\(String(reflecting: s))"
        case .intConst(let i):    return "\(i))"
        case .floatConst(let d):  return "\(d))"
        case .stringConst(let s): return "\(String(reflecting: s))"

        case .proc: return "proc"
        case .funcTok: return "func"
        case .children: return "children"
        case .spouses: return "spouses"
        case .ifTok: return "if"
        case .elseTok: return "else"
        case .elsif: return "elsif"
        case .families: return "families"
        case .whileTok: return "while"
        case .call: return "call"
        case .forindiset: return "forindiset"
        case .forindi: return "forindi"
        case .fornotes: return "fornotes"
        case .traverse: return "traverse"
        case .fornodes: return "fornodes"
        case .forlist: return "forlist"
        case .forfam: return "forfam"
        case .forsour: return "forsour"
        case .foreven: return "foreven"
        case .forothr: return "forothr"
        case .breakTok: return "break"
        case .continueTok: return "continue"
        case .returnTok: return "return"
        case .fathers: return "fathers"
        case .mothers: return "mothers"
        case .parents: return "parents"

        case .lParen: return "()"
        case .rParen: return ")"
        case .lBrace: return "{"
        case .rBrace: return "}"
        case .comma: return ","
        case .slash: return "/"
        case .minus: return "-"
        case .period: return "."
        case .eof: return "eof"
        case .unknown: return "?"
        }
    }
}
