//
//  ParsedStructs.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 8 April 2026.
//  Last changed on 1 September 2026.
//

import Foundation

/// Parsed program, holding the syntax tree of an entire program.
public struct ParsedProgram: Equatable, CustomStringConvertible {

    let defns: [ParsedDefn]  // A program is a list of definitions.
    let procURLs: [String:URL?]
    let funcURLs: [String:URL?]

    public init(_ defns: [ParsedDefn], procURLs: [String:URL?] = [:],
                funcURLs: [String:URL?] = [:]) {
        self.defns = defns
        self.procURLs = procURLs
        self.funcURLs = funcURLs
    }

    public var description: String {
        defns.map(\.description).joined(separator: "\n")
    }
}

/// Parsed definition; holds one of the four definition types found in programs.
public enum ParsedDefn: Equatable, CustomStringConvertible {

    case procDefn(ParsedProcDefn)  // Procedure definition.
    case funcDefn(ParsedFuncDefn)  // Function definition.
    case global(ParsedGlobalDefn)  // Global definition.
    case include(ParsedIncludeDefn) // Include definition.

    public var description: String {
        switch self {
        case .procDefn(let procDefn): return procDefn.description
        case .funcDefn(let funcDefn): return funcDefn.description
        case .global(let global): return global.description
        case .include(let include): return include.description
        }
    }

    var name: String {
        switch self {
        case .procDefn(let defn):
            return defn.name
        case .funcDefn(let defn):
            return defn.name
        case .global(let defn):
            return defn.name
        case .include(let defn):
            return defn.name
        }
    }

    var line: Int {
        switch self {
        case .procDefn(let defn):
            return defn.line
        case .funcDefn(let defn):
            return defn.line
        case .global(let defn):
            return defn.line
        case .include(let defn):
            return defn.line
        }
    }
}

/// Parsed procedure definition, the definition of a user procedure.
public struct ParsedProcDefn: Equatable, CustomStringConvertible {

    let name: String
    let params: [String]
    let body: [ParsedStatement]
    let line: Int

    public var description: String {
        "proc \(name)(\(params.joined(separator: ", "))) \(body)"
    }
}

/// Parsed function definition, the definition of a user function.
public struct ParsedFuncDefn: Equatable, CustomStringConvertible {

    let name: String
    let params: [String]
    let body: [ParsedStatement]
    let line: Int

    public var description: String {
        "FUNC \(name)(\(params.joined(separator: ", "))) \(body)"
    }
}

/// Parsed global definition, the definition of a global variable.
public struct ParsedGlobalDefn: Equatable, CustomStringConvertible {

    let name: String
    let line: Int

    public var description: String {
        "GLOBAL(\(name))"
    }
}

/// Parsed include definition, the "definition" of an include file.
public struct ParsedIncludeDefn: Equatable, CustomStringConvertible {

    let name: String
    let line: Int

    public var description: String {
        "INCUDE(\(name))"
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
        case forEachStatement(ParsedForEachStmt)
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
        case .forEachStatement(let s): return s.description
        case .expressionStatement(let e): return "EXPRSTMT(\(e))"
        }
    }
}

/// Parsed call statement.
struct ParsedCallStatement: Equatable, CustomStringConvertible {

    let name: String  // Name of the procedure.
    let args: [ParsedExpr]  // Argument expressions.
    let line: Int  // Line number in program.

    var description: String {
        let argDescriptions = args.map { expr in
            expr.description
        }
        return "call \(name)(\(argDescriptions.joined(separator: ", ")))"
    }
}

/// Parsed while statement.
struct ParsedWhileStmt: Equatable, CustomStringConvertible {

    let condition: ParsedCondition  // Condition expression.
    let body: [ParsedStatement]  // Body of the while loop.
    let line: Int  // Line number in program.

    var description: String { "while(\(condition)) { \(body) }" }
}

/// Parsed if statement.
struct ParsedIfStmt: Equatable, CustomStringConvertible {

    let condition: ParsedCondition  // Condition expression.
    let thenBody: [ParsedStatement]  // Then clause.
    let elseIfs: [ParsedElseIf]  // Else if clauses.
    let elseBody: [ParsedStatement]?  // Final else clause.
    let line: Int  // Line number in program.

    var description: String {
        "if(\(condition)) then \(thenBody) elsifs \(elseIfs) else \(String(describing: elseBody))"
    }
}

/// Parsed else if statement.
struct ParsedElseIf: Equatable, CustomStringConvertible {

    let condition: ParsedCondition  // Conditional expression
    let body: [ParsedStatement]  // Statements in else if clause.
    let line: Int  // Line nummber if program.

    var description: String { "elsif(\(condition)) \(body)" }
}

/// Parsed return statement.
struct ParsedReturnStmt: Equatable, CustomStringConvertible {
    
    let values: [ParsedExpr]  // Return expressions.

    var description: String { "return(\(values))" }
}

/// Parsed break statement.
struct ParsedBreakStmt: Equatable, CustomStringConvertible {

    var description: String { "break()" }
}

/// Parse continue statement.
struct ParsedContinueStmt: Equatable, CustomStringConvertible {

    var description: String { "continue()" }
}

/// Parsed foreach statement -- foreach(ListExpr, var[, var], var)
struct ParsedForEachStmt: Equatable, CustomStringConvertible {

    let listExpr: ParsedExpr  // List expression.
    let elementVar: String  // Ident assigned to value of each element.
    let valueVar: String?  // Ident assiged to the associated value of the element when meaningful.
    let indexVar: String  // Ident assigned to index number of each eleent.
    let body: [ParsedStatement]  // Statements making up the body of the loop.
    let line: Int  // Line in program where the statement starts.

    var description: String {
        "foreach(\(listExpr), \(elementVar), \(indexVar)) { ... }"
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
