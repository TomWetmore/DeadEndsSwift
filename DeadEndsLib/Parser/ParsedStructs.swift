//
//  ParsedStructs.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 8 April 2026.
//  Last changed on 8 April 2026.
//

/// The parsed structs (and enums) make up the "abstract syntax tree"
/// of a DeadEnds program. They are all value types so the syntax tree
/// is a fully formed constructed value object with no pointers.
/// Theoretically this is a fine Swift approach. As an abstract syntax
/// tree these parsed objects are never changed as they respresent the
/// static program, not its execution.

import Foundation

/// Parsed program struct.
struct ParsedProgram: Equatable, CustomStringConvertible {

    let defns: [ParsedDefn]  // A program is a list of definitions.

    var description: String {
        defns.map(\.description).joined(separator: "\n")
    }
}

/// Parsed definition.
enum ParsedDefn: Equatable, CustomStringConvertible {
    
    case procDef(ParsedProcDef)  // Procedure definition.
    case funcDef(ParsedFuncDef)  // Function definition.
    case global(ParsedGlobalDef)  // Global definition.

    var description: String {
        switch self {
        case .procDef(let p): return p.description
        case .funcDef(let f): return f.description
        case .global(let g): return g.description
        }
    }
}

/// Parsed procedure definition.
struct ParsedProcDef: Equatable, CustomStringConvertible {

    let name: String
    let params: [String]
    let body: [ParsedStmt]

    var description: String {
        "PROC \(name)(\(params.joined(separator: ", "))) \(body)"
    }
}

/// Parsed function definition.
struct ParsedFuncDef: Equatable, CustomStringConvertible {

    let name: String
    let params: [String]
    let body: [ParsedStmt]

    var description: String {
        "FUNC \(name)(\(params.joined(separator: ", "))) \(body)"
    }
}

/// Parsed global definition.
struct ParsedGlobalDef: Equatable, CustomStringConvertible {

    let name: String

    var description: String {
        "GLOBAL(\(name))"
    }
}

/// Parsed statement types.
enum ParsedStmt: Equatable, CustomStringConvertible {
    
    case callStmt(ParsedCallStmt)
    case whileStmt(ParsedWhileStmt)
    case ifStmt(ParsedIfStmt)
    case returnStmt(ParsedReturnStmt)
    case breakStmt(ParsedBreakStmt)
    case continueStmt(ParsedContinueStmt)
    case exprStmt(ParsedExpr)

    var description: String {
        switch self {
        case .callStmt(let s):         return s.description
        case .whileStmt(let s):    return s.description
        case .ifStmt(let s):       return s.description
        case .returnStmt(let s):   return s.description
        case .breakStmt(let s):    return s.description
        case .continueStmt(let s): return s.description
        case .exprStmt(let e):         return "EXPRSTMT(\(e))"
        }
    }
}

/// Parsed call statement.
struct ParsedCallStmt: Equatable, CustomStringConvertible {

    let name: String
    let args: [ParsedExpr]

    var description: String {
        "CALL \(name)(\(args.map(\.description).joined(separator: ", ")))"
    }
}

/// Parsed while statement.
struct ParsedWhileStmt: Equatable, CustomStringConvertible {

    let condition: ParsedCondition
    let body: [ParsedStmt]

    var description: String {
        "WHILE(\(condition)) { \(body) }"
    }
}

/// Parsed if statement.
struct ParsedIfStmt: Equatable, CustomStringConvertible {

    let condition: ParsedCondition
    let thenBody: [ParsedStmt]
    let elseIfs: [ParsedElseIf]
    let elseBody: [ParsedStmt]?

    var description: String {
        "IF(\(condition)) THEN \(thenBody) ELSIFS \(elseIfs) ELSE \(String(describing: elseBody))"
    }
}

/// Parsed else if statement.
struct ParsedElseIf: Equatable, CustomStringConvertible {
    
    let condition: ParsedCondition
    let body: [ParsedStmt]

    var description: String {
        "ELSIF(\(condition)) \(body)"
    }
}

/// Parsed return statement.
struct ParsedReturnStmt: Equatable, CustomStringConvertible {
    let values: [ParsedExpr]

    var description: String {
        "RETURN(\(values))"
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
enum ParsedExpr: Equatable, CustomStringConvertible {
    
    case identifier(String)
    case intConst(Int)
    case floatConst(Double)
    case stringConst(String)
    case funcCall(String, [ParsedExpr])

    var description: String {
        switch self {
        case .identifier(let s):         return "id(\(s))"
        case .intConst(let i):           return "int(\(i))"
        case .floatConst(let f):         return "float(\(f))"
        case .stringConst(let s):        return "str(\(String(reflecting: s)))"
        case .funcCall(let name, let a): return "call(\(name), \(a))"
        }
    }
}
