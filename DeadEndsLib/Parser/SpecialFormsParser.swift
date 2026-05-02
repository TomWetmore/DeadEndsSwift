//
//  SpecialFormsParser.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 1 May 2026.
//  Last changed on 1 May 2026.
//

import Foundation
import Parsing

struct ForListStmtParser: Parser {

    func parse(_ input: inout TokStream) throws -> ParsedForListStmt {
        let line = input.first?.line ?? 0

        try ExactToken(kind: .forlist).parse(&input)
        try ExactToken(kind: .lParen).parse(&input)

        let listExpr = try ExprParser().parse(&input)

        try ExactToken(kind: .comma).parse(&input)
        let elementVar = try IdentifierToken().parse(&input)

        try ExactToken(kind: .comma).parse(&input)
        let indexVar = try IdentifierToken().parse(&input)

        try ExactToken(kind: .rParen).parse(&input)
        try ExactToken(kind: .lBrace).parse(&input)

        let body = try StmtListParser().parse(&input)

        try ExactToken(kind: .rBrace).parse(&input)

        return ParsedForListStmt(listExpr: listExpr, elementVar: elementVar, indexVar: indexVar, body: body, line: line)
    }
}

struct ForIndisetStmtParser: Parser {

    /// Parser for forindiset(indiset, indi, value, count) { ... }
    func parse(_ input: inout TokStream) throws -> ParsedForIndisetStmt {
        let line = input.first?.line ?? 0
        try ExactToken(kind: .forindiset).parse(&input)    // forindiset
        try ExactToken(kind: .lParen).parse(&input)        // (
        let setExpr = try ExprParser().parse(&input)       // indiset
        try ExactToken(kind: .comma).parse(&input)         // ,
        let indiVar = try IdentifierToken().parse(&input)  // indi
        try ExactToken(kind: .comma).parse(&input)         // ,
        let anyVar = try IdentifierToken().parse(&input)   // value
        try ExactToken(kind: .comma).parse(&input)         // ,
        let countVar = try IdentifierToken().parse(&input) // index
        try ExactToken(kind: .rParen).parse(&input)        // )
        try ExactToken(kind: .lBrace).parse(&input)        // {
        let body = try StmtListParser().parse(&input)      // body statements
        try ExactToken(kind: .rBrace).parse(&input)        // }

        return ParsedForIndisetStmt(
            indisetExpr: setExpr,
            indiVar: indiVar,
            valueVar: anyVar,
            indexVar: countVar,
            body: body,
            line: line
        )
    }
}
