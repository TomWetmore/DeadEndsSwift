//
//  SpecialFormsParser.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 1 May 2026.
//  Last changed on 8 May 2026.
//

import Foundation
import Parsing

struct ForEachStmtParser: Parser {

    func parse(_ input: inout TokStream) throws -> ParsedForEachStmt {
        let line = input.first?.line ?? 0

        try ExactToken(kind: .foreach).parse(&input)          // forlist
        try ExactToken(kind: .lParen).parse(&input)           // (

        let listExpr = try ExprParser().parse(&input)         // collection

        try ExactToken(kind: .comma).parse(&input)            // ,
        let elementVar = try IdentifierToken().parse(&input)  // element

        try ExactToken(kind: .comma).parse(&input)            // ,

        // valueVar or indexVar
        let thirdName = try IdentifierToken().parse(&input)

        var valueVar: String? = nil
        let indexVar: String

        if let _ = try? ExactToken(kind: .comma).parse(&input) {
            valueVar = thirdName  // Four argument form.
            indexVar = try IdentifierToken().parse(&input)
        } else {
            indexVar = thirdName // Three argument form.
        }

        try ExactToken(kind: .rParen).parse(&input)           // )
        try ExactToken(kind: .lBrace).parse(&input)           // {

        let body = try StmtListParser().parse(&input)         // body statements

        try ExactToken(kind: .rBrace).parse(&input)           // }

        return ParsedForEachStmt(
            listExpr: listExpr,
            elementVar: elementVar,
            valueVar: valueVar,
            indexVar: indexVar,
            body: body,
            line: line
        )
    }
}
