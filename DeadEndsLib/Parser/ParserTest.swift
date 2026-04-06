//
//  ParserTest.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 4/6/26.
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
