//
//  ParserTest.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 6 April 2026.
//  Last changed 6 April 2026.
//

import Foundation
import Parsing

public func testParser() {

    parseTokens(IdentifierToken(), from: "foo")
    parseTokens(ExprParser(), from: "foo")
    parseTokens(ExprParser(), from: "123")
    parseTokens(ExprParser(), from: "\"abc\\n\"")
    parseTokens(ExprParser(), from: "father(person)")
    parseTokens(ExprListParser(), from: "a, 123, \"x\", mother(p)")
    parseTokens(CallStmtParser(), from: "call showevent(29, birth(indi), 0, 0)")
    parseTokens(CallStmtParser(), from: "call setupabbvtab()")

    parseTokens(WhileStmtParser(), from: "while(a, 1) { \"abc\" }")

    parseTokens(IfStmtParser(), from: "if (b, 1) { 42 } else { 43 }" )
}

public func parseTokens<P: Parser, T>(_ parser: P, from source: String)
        where P.Input == TokStream, P.Output == T {
            
    var lexer = Lexer(source: source)
    let tokens = lexer.tokenize()

    print("SOURCE:")
    print(source)
    print("\nTOKENS:")
    for tok in tokens {
        print("  \(tok)")
    }

    var input = tokens[...]
    do {
        let result = try parser.parse(&input)
        print("\nPARSE RESULT:")
        print(result)

        print("\nREMAINING TOKENS:")
        for tok in input {
            print("  \(tok)")
        }
    } catch {
        print("\nPARSE FAILED:")
        print(error)
    }

    print("\n-----------------------------\n")
}

/*
 This is a test harness for parsers. Given a parser that parses tokens, and
 given a source, this runs the lexer on the string, feeds the tokens to the
 parser, and prints results.

 The parser must conform to the Parser protocol, with a TokString input and
 output type T. P is the type of the parser, and T is the type of the result.

 When you call "parseTokens(IdentifierToken(), from: "foo")", Swift infers that
 P = IdentifierToken and  T = String.  This function adapts to many parser/result
 combinations.

 tokens is an array: [Token], and tokens[...] is an ArraySlice<Token>. Note the
 earlier definition " typealias TokStream = ArraySlice<Token>", so input is the
 token stream that the parser expects.

 Why a slice instead of an array? Because parsers in this style consume input by
 modifying the slice in place. The parser sees only the unconsumed tail of input.

 So if the tokens are initially "[call, identifier("foo"), lParen, rParen, eof]"
 then before parsing input refers to the whole slice. After parsing call foo(),
 input may now refer only to: [eof]

 This line is the most important operational line:

 let result = try parser.parse(&input)

 It means to call the parser passed in, let it read from and modify input, and
 return the value it parsed.

 The &input is like passing by reference. The parser mutates the token stream,
 removing the part it consumes.

 A parser is a thing that takes a mutable input stream and either: a) succeeds,
 returning a value and consuming some input, or b) fails by throwing an error

 Psuedo code:
 function parseTokens(parser, sourceString):
      lex the sourceString into tokens
      print the source
      print the tokens
      make a mutable token stream from the token array
      try:
          result = parser.parse(tokenStream)
          print the result
          print whatever tokens remain after parsing
      catch:
          print the error

 */
