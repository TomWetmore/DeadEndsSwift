//
//  ParsedStructs.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 8 April 2026.
//  Last changed on 2 May 2026.
//

/// The parsed structs and enums make up the "abstract syntax tree" of
/// a DeadEnds program. They are value types so the syntax tree fully
/// formed value object with no pointers. As abstract syntax trees
/// these parsed objects are never changed. They represent the static
/// program, not its execution.

import Foundation

/// Parsed program, holding the syntax tree of an entire program.
public struct ParsedProgram: Equatable, CustomStringConvertible {

    let defns: [ParsedDefn]  // A program is a list of definitions.

    public var description: String {
        defns.map(\.description).joined(separator: "\n")
    }
}

/// Parsed definition, holding the three definition types that
/// make up a program.
enum ParsedDefn: Equatable, CustomStringConvertible {
    
    case procDef(ParsedProcDefn)  // Procedure definition.
    case funcDef(ParsedFuncDefn)  // Function definition.
    case global(ParsedGlobalDefn)  // Global definition.

    var description: String {
        switch self {
        case .procDef(let p): return p.description
        case .funcDef(let f): return f.description
        case .global(let g): return g.description
        }
    }
}

/// Parsed procedure definition, holding the definition of a
/// user procedure.
struct ParsedProcDefn: Equatable, CustomStringConvertible {

    let name: String
    let params: [String]
    let body: [ParsedStatement]
    let line: Int

    var description: String {
        "proc \(name)(\(params.joined(separator: ", "))) \(body)"
    }
}

/// Parsed function definition, holding the definition of a
/// user function.
struct ParsedFuncDefn: Equatable, CustomStringConvertible {

    let name: String
    let params: [String]
    let body: [ParsedStatement]
    let line: Int

    var description: String {
        "FUNC \(name)(\(params.joined(separator: ", "))) \(body)"
    }
}

/// Parsed global definition, holding the definition of a
/// global variable.
struct ParsedGlobalDefn: Equatable, CustomStringConvertible {

    let name: String
    let line: Int

    var description: String {
        "GLOBAL(\(name))"
    }
}

/// Parsed statement types.
struct ParsedStatement: Equatable, CustomStringConvertible {

    var kind: Kind
    var line: Int

    enum Kind: Equatable {

        case callStatement(ParsedCallStatement)
        case whileStatement(ParsedWhileStmt)
        case ifStatement(ParsedIfStmt)
        case returnStatement(ParsedReturnStmt)
        case breakStatement(ParsedBreakStmt)
        case continueStatement(ParsedContinueStmt)
        case forListStatement(ParsedForListStmt)
        case forIndisetStatement(ParsedForIndisetStmt)
        case forSpousesStatement(ParsedForspousesStmt)
        case expressionStatement(ParsedExpr)
    }

    var description: String {
        switch kind {
        case .callStatement(let s): return s.description
        case .whileStatement(let s): return s.description
        case .ifStatement(let s): return s.description
        case .returnStatement(let s): return s.description
        case .breakStatement(let s): return s.description
        case .continueStatement(let s): return s.description
        case .forListStatement(let s): return s.description
        case .forIndisetStatement(let s): return s.description
        case .forSpousesStatement(let s): return s.description
        case .expressionStatement(let e): return "EXPRSTMT(\(e))"
        }
    }
}

/// Parsed call statement.
struct ParsedCallStatement: Equatable, CustomStringConvertible {

    let name: String
    let args: [ParsedExpr]
    let line: Int

    var description: String {
        let argDescriptions = args.map { expr in
            expr.description
        }
        return "call \(name)(\(argDescriptions.joined(separator: ", ")))"
    }
}

/// Parsed while statement.
struct ParsedWhileStmt: Equatable, CustomStringConvertible {

    let condition: ParsedCondition
    let body: [ParsedStatement]
    let line: Int

    var description: String {
        "while(\(condition)) { \(body) }"
    }
}

/// Parsed if statement.
struct ParsedIfStmt: Equatable, CustomStringConvertible {

    let condition: ParsedCondition
    let thenBody: [ParsedStatement]
    let elseIfs: [ParsedElseIf]
    let elseBody: [ParsedStatement]?
    let line: Int

    var description: String {
        "if(\(condition)) then \(thenBody) elsifs \(elseIfs) else \(String(describing: elseBody))"
    }
}

/// Parsed else if statement.
struct ParsedElseIf: Equatable, CustomStringConvertible {
    
    let condition: ParsedCondition
    let body: [ParsedStatement]
    let line: Int

    var description: String {
        "elsif(\(condition)) \(body)"
    }
}

/// Parsed return statement.
struct ParsedReturnStmt: Equatable, CustomStringConvertible {
    let values: [ParsedExpr]

    var description: String {

        "return(\(values))"
    }
}

/// Parsed break statement.
struct ParsedBreakStmt: Equatable, CustomStringConvertible {

    var description: String { "BREAK()" }
}

/// Parse continue statement.
struct ParsedContinueStmt: Equatable, CustomStringConvertible {
    
    var description: String { "CONTINUE()" }
}

/// SPECIAL STATEMENT FORMS ///

/// Parsed structure for a list statement -- forlist(list, var, var)
struct ParsedForListStmt: Equatable, CustomStringConvertible {
    
    let listExpr: ParsedExpr
    let elementVar: String
    let indexVar: String
    let body: [ParsedStatement]
    let line: Int

    var description: String {
        "forlist(\(listExpr), \(elementVar), \(indexVar)) { ... }"
    }
}

/// Parsed structure for an indiset statement -- forindiset(indiset, indi, any, index)
struct ParsedForIndisetStmt: Equatable, CustomStringConvertible {

    // What are the parts of a forindiset loop to we need?
    let indisetExpr: ParsedExpr
    let indiVar: String
    let valueVar: String
    let indexVar: String
    let body: [ParsedStatement]
    let line: Int

    var description: String {
        "forindiset(\(indisetExpr), \(indiVar), \(valueVar), \(indexVar)) { ... }"
    }
}

/// Parsed structure for a forspouses statement -- forspouses(indi, spouse, index)
struct ParsedForspousesStmt: Equatable, CustomStringConvertible {

    let personExpr: ParsedExpr
    let spouseVar: String
    let familyVar: String
    let indexVar: String
    let body: [ParsedStatement]
    let line: Int

    var description: String {
        "forspouses(\(personExpr), \(spouseVar), \(indexVar)) { ... }"
    }
}

/// Parsed conditional expression.
enum ParsedCondition: Equatable, CustomStringConvertible {

    case expr(ParsedExpr)
    case assign(String, ParsedExpr)

    var description: String {
        switch self {
        case .expr(let e):
            return "cond(\(e))"
        case .assign(let name, let expr):
            return "condAssign(\(name), \(expr))"
        }
    }
}

/// Parsed expressions.
struct ParsedExpr: Equatable, CustomStringConvertible {
    let kind: Kind
    let line: Int

    enum Kind: Equatable {
        case identifier(String)
        case integerConstant(Int)
        case doubleConstant(Double)
        case stringConstant(String)
        case functionCall(String, [ParsedExpr])
    }
    var description: String {
        switch kind {
        case .identifier(let s): return "id(\(s))"
        case .integerConstant(let i): return "int(\(i))"
        case .doubleConstant(let f): return "float(\(f))"
        case .stringConstant(let s): return "str(\(String(reflecting: s)))"
        case .functionCall(let name, let a): return "funccall(\(name), \(a))"
        }
    }
}

