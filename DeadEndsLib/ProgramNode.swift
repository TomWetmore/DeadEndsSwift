//
//  ProgramNode.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 2 March 2025.
//  Last changed on 28 April 2025.
//

import Foundation

// ProgramNode is the type of program or script nodes. The parser builds abstract syntax trees out of ProgramNodes
// for the procedures and functions. ProgramNodes represent statements and unevaluated expressions. The interpreter
// 'executes' the ProgramNode trees.
public class ProgramNode: CustomStringConvertible {

    // Kind enumerates the types of ProgramNodes and their associated values.
    enum Kind {
        case integer(Int)
        case double(Double)
        case string(String)
        case identifier(String)
        case procedureDef(name: String, params: [String], body: ProgramNode)
        case functionDef(name: String, params: [String], body: ProgramNode)
        case procedureCall(name: String, args: [ProgramNode])
        case functionCall(name: String, args: [ProgramNode])
        case builtinCall(name: String, args: [ProgramNode])
        case globalDecl(String) // NEW: JUST ADDED: REMOVE COMMENT WHEN WORKING!!
        case ifState(condition: [ProgramNode], thenc: ProgramNode, elsec: ProgramNode?)
        case whileState(condition: [ProgramNode], body: ProgramNode)
        case returnState(result: ProgramNode?)
        case breakState
        case continueState
        case block(statements: [ProgramNode])
        case children(family: ProgramNode, child: String, count: String)

        case persons(person: String, count: String, body: ProgramNode)
        case families(family: String, count: String, body: ProgramNode)
        case sources(source: String, count: String, body: ProgramNode)
        case events(event: String, count: String, body: ProgramNode)
        case others(other: String, count: String, body: ProgramNode)

        case list(list: ProgramNode, element: String, count: String, body: ProgramNode)
        case sequence(sequence: ProgramNode, element: String, count: String, body: ProgramNode)
        case table(table: ProgramNode, body: ProgramNode)
        case fathers(person: ProgramNode, father: String, body: ProgramNode)
        case mothers(person: ProgramNode, mother: String, body: ProgramNode)
        case famsAsSpouse(person: ProgramNode, family: String, body: ProgramNode)
        case famsAsChild(person: ProgramNode, family: String, body: ProgramNode)

        case traverse(root: ProgramNode, node: String, level: String, body: ProgramNode)
        case nodes
        case notes
    }

    let kind: Kind
    let line: Int?
    let file: String?

    // init initializes a ProgramNode with common fields. Static functions in an extension create the specific
    // ProgramNode value types.
    init(kind: ProgramNode.Kind, line: Int? = nil, file: String? = nil) {
        self.kind = kind
        self.line = line
        self.file = file
    }

    // description returns a description of a ProgramNode.
    public var description: String {
        switch kind {
        case .integer(let integer):
            return "\(integer)"
        case .double(let double):
            return "\(double)"
        case .string(let string):
            return "\"\(string)\""
        case .identifier(idvalue: let id):
            return "\(id)"
        case .ifState(_, _, _):
            return ifDescription(ifState: self)
        case .whileState(_, _):
            return whileDescription(whileState: self)
        case .continueState:
            return "continue"
        case .breakState:
            return "break"
        case .returnState(result: let result):
            return result.map { "return(\($0.description))" } ?? "return"
        case let .block(statements):
            let buf = statements.map { $0.description }.joined(separator: " ")
            return "{ \(buf) }"
        case let .globalDecl(name):
            return "global(\(name))"
        case let .procedureDef(name, params, body):
            let paramList = params.joined(separator: " ")
            let bodyDesc = body.description
            return "proc \(name)(\(paramList)) \(bodyDesc)"
        case let .procedureCall(name, args):
            let argList = args.map { $0.description }.joined(separator: " ")
            return "call \(name)(\(argList))"
        case let .functionDef(name, params, body):
            let paramList = params.joined(separator: " ")
            let bodyDesc = body.description
            return "func \(name)(\(paramList)) \(bodyDesc)"
        case let .functionCall(name, args):
            let argList = args.map { $0.description }.joined(separator: " ")
            return "\(name)(\(argList))"
        case let .builtinCall(name: name, args: args):
            let argList = args.map { $0.description }.joined(separator: " ")
            return "\(name)(\(argList))"

        default:
            return "write me"
        }
    }
    //        case let .children(family, child, count):
    //            return "children \(family.description) as \(child), count \(count)"
    //
    //        case let .persons(person, count, body):
    //            return "forperson \(person), count \(count) \(body.description)"
    //
    //        case let .families(family, count, body):
    //            return "forfamily \(family), count \(count) \(body.description)"
    //
    //        case let .sources(source, count, body):
    //            return "forsource \(source), count \(count) \(body.description)"
    //
    //        case let .events(event, count, body):
    //            return "forevent \(event), count \(count) \(body.description)"
    //
    //        case let .others(other, count, body):
    //            return "forother \(other), count \(count) \(body.description)"
    //
    //        case let .list(list, element, count, body):
    //            return "forlist \(list.description) as \(element), count \(count) \(body.description)"
    //
    //        case let .sequence(sequence, element, count, body):
    //            return "sequence \(sequence.description) as \(element), count \(count) \(body.description)"
    //
    //        case let .table(table, body):
    //            return "fortable \(table.description) \(body.description)"
    //
    //        case let .fathers(person, father, body):
    //            return "fathers \(person.description) as \(father) \(body.description)"
    //
    //        case let .mothers(person, mother, body):
    //            return "mothers \(person.description) as \(mother) \(body.description)"
    //
    //        case let .famsAsSpouse(person, family, body):
    //            return "famsAsSpouse \(person.description) in \(family) \(body.description)"
    //
    //        case let .famsAsChild(person, family, body):
    //            return "famsAsChild \(person.description) in \(family) \(body.description)"
    //
    //        case let .traverse(root, node, level, body):
    //            return "traverse \(root.description) as \(node) at level \(level) \(body.description)"
    //        case .nodes:
    //            return "<nodes>"
    //        case .notes:
    //            return "<notes>"
    //        }
    //    }
}

// ProgramNode extension with the factory methods that create ProgramNodes.
extension ProgramNode {
    static func integer(_ integer: Int, line: Int? = nil, file: String? = nil) -> ProgramNode {
        ProgramNode(kind: .integer(integer), line: line, file: file)
    }

    static func float(_ double: Double, line: Int? = nil, file: String? = nil) -> ProgramNode {
        ProgramNode(kind: .double(double))
    }

    static func string(_ string: String, line: Int? = nil, file: String? = nil) -> ProgramNode {
        ProgramNode(kind: .string(string))
    }

    static func identifier(_ name: String, line: Int? = nil, file: String? = nil) -> ProgramNode {
        ProgramNode(kind: .identifier(name))
    }

    // ifStatement creates an .ifStatement ProgramNode.
    static func ifStatement(cond: [ProgramNode], thenC: ProgramNode, elseC: ProgramNode? = nil, line: Int? = nil,
                            file: String? = nil) -> ProgramNode {
        ProgramNode(kind: .ifState(condition: cond, thenc: thenC, elsec: elseC), line: line, file: file)
    }

    // whileState creates a .whileState ProgramNode.
    static func whileStatement(cond: [ProgramNode], body: ProgramNode, line: Int? = nil, file: String? = nil) -> ProgramNode {
        ProgramNode(kind: .whileState(condition: cond, body: body), line: line, file: file)
    }

    // returnState creates a returnState ProgramNode. Return states have an optional return value.
    static func returnState(result: ProgramNode?, line: Int? = nil, file: String? = nil) -> ProgramNode {
        ProgramNode(kind: .returnState(result: result), line: line, file: file)
    }

    // continueState creates a .breakState ProgramNode.
    static func continueState(line: Int? = nil, file: String? = nil) -> ProgramNode {
        ProgramNode(kind: .continueState, line: line, file: file)
    }

    // breakState creates a .breakState ProgramNode.
    static func breakState(line: Int? = nil, file: String? = nil) -> ProgramNode {
        ProgramNode(kind: .breakState, line: line, file: file)
    }

    // procedureDef creates a .procedureDef ProgramNode.
    static func procedureDef(name: String, params: [String], body: ProgramNode, line: Int? = nil, file: String? = nil) -> ProgramNode {
        ProgramNode(kind: .procedureDef(name: name, params: params, body: body), line: line, file: file)
    }

    // functionDef creates a .functionDef ProgramNode.
    static func functionDef(name: String, params: [String], body: ProgramNode, line: Int? = nil, file: String? = nil) -> ProgramNode {
        ProgramNode(kind: .functionDef(name: name, params: params, body: body), line: line, file: file)
    }

    // procedureCall creates a .procedureCall ProgramNode.
    static func procedureCall(name: String, args: [ProgramNode], line: Int? = nil, file: String? = nil) -> ProgramNode {
        ProgramNode(kind: .procedureCall(name: name, args: args), line: line, file: file)
    }

    // functionCall creates a .functionCall ProgramNode.
    static func functionCall(name: String, args: [ProgramNode], line: Int? = nil, file: String? = nil) -> ProgramNode {
        ProgramNode(kind: .functionCall(name: name, args: args), line: line, file: file)
    }

    // builtinCall creates a .builtInCall ProgramNode.
    static func builtinCall(name: String, args: [ProgramNode], line: Int? = nil, file: String? = nil) -> ProgramNode {
        ProgramNode(kind: .builtinCall(name: name, args: args), line: line, file: file)
    }

    // persons returns a ProgramNode for the all persons in database loop.
    static func persons(person: String, count: String, body: ProgramNode, line: Int? = nil, file: String? = nil) -> ProgramNode {
        ProgramNode(kind: .persons(person: person, count: count, body: body), line: line, file: file)
    }

    // families returns a ProgramNode for the all families in database loop.
    static func families(family: String, count: String, body: ProgramNode, line: Int? = nil, file: String? = nil) -> ProgramNode {
        ProgramNode(kind: .families(family: family, count: count, body: body), line: line, file: file)
    }

    // sources returns a ProgramNode for the all sources in database loop.
    static func sources(source: String, count: String, body: ProgramNode, line: Int? = nil, file: String? = nil) -> ProgramNode {
        ProgramNode(kind: .sources(source: source, count: count, body: body), line: line, file: file)
    }

    // events returns a ProgramNode for the all events in database loop.
    static func events(event: String, count: String, body: ProgramNode, line: Int? = nil, file: String? = nil) -> ProgramNode {
        ProgramNode(kind: .events(event: event, count: count, body: body), line: line, file: file)
    }

    // others returns a ProgramNode for the all other records in database loop
    static func others(other: String, count: String, body: ProgramNode, line: Int? = nil, file: String? = nil) -> ProgramNode {
        ProgramNode(kind: .others(other: other, count: count, body: body), line: line, file: file)
    }

    // traverse returns a ProgramNode for the traverse below a Node function
    static func traverse(root: ProgramNode, node: String, level: String, body: ProgramNode, line: Int? = nil,
                         file: String? = nil) -> ProgramNode {
        ProgramNode(kind: .traverse(root: root, node: node, level: level, body: body), line: line, file: file)
    }

    static func children(family: ProgramNode, child: String, count: String, line: Int? = nil, file: String? = nil) -> ProgramNode {
        ProgramNode(kind: .children(family: family, child: child, count: count), line: line, file: file)
    }
}

// ProgramNode debugging extension with description functions for ProgramNodes.
extension ProgramNode {

    // ifDescription returns the description of an if ProgramNode.
    func ifDescription(ifState: ProgramNode) -> String {
        guard case let .ifState(cond, thenc, elsec) = kind else { return "NOT AN IF STATEMENT" }
        let elsestr = elsec == nil ? "" : " \(elsec!)"
        return "if \(conditionDescription(cond)) \(thenc)\(elsestr)"
    }

    // whileDescription returns the description of a while ProgramNode.
    func whileDescription(whileState: ProgramNode) -> String {
        guard case let .whileState(cond, body) = kind else { return "NOT A WHILE STATEMENT" }
        return "while \(conditionDescription(cond)) \(body)"
    }

    // conditionDescription returns the descriptionof a [ProgramNode] condition.
    func conditionDescription(_ condition: [ProgramNode]) -> String {
        if condition.count == 1 {
            return "(\(condition[0]))"
        } else {
            return "(\(condition[0]), \(condition[1]))"
        }
    }
}

// ProgramNode extension with computed properties that simplify access components of some ProgramNode.
extension ProgramNode {

    // asProcedureDef takes an assumed .procedureDef ProgramNode and returns its name, parameters, and body.
    var asProcedureDef: (name: String, params: [String], body: ProgramNode)? {
        if case let .procedureDef(name, params, body) = self.kind { return (name, params, body) }
        return nil
    }

    // asFunctionDef takes an assumed .functionDef ProgramNode and returns its name, parameters, and body.
    var asFunctionDef: (name: String, params: [String], body: ProgramNode)? {
        if case let .functionDef(name, params, body) = self.kind { return (name, params, body) }
        return nil
    }
}

