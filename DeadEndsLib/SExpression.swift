//
//  SExpression.swift
//  DeadEndsLib
//  SExpressions are used as a transfer format for DeadEnds programs. A LifeLines-based C program parses
//  DeadEnds programs and then writes them to text files as SExpressions. This Swift program reads those
//  SExpressions and builds ProgramNode trees for the original DeadEnds progrem. Those ProgramNode trees
//  are interpreted by this program's interpreter component.
//
//  Note: It is possible to interpret SExpressions's directly instead of converting them to ProgramNodes. This
//  may be a future enhancement.
//
//  Created by Thomas Wetmore on 5 April 2025.
//  Last changed on 21 April 2025.
//

import Foundation

// SExpression is the data type used to transfer DeadEnds programs as text files.
public enum SExpression: CustomStringConvertible {

    case atom(String, line: Int?) // Atoms (constants, identifiers, strings) with optional line number.
    case list([SExpression])  // Lists (nested expressions).

    // description describes an SExpression.
    public var description: String {
        switch self {
        case .atom(let value, let line):
            if let line = line {
                return "\(value)[\(line)]"
            } else {
                return value
            }
        case .list(let elements):
            return "(" + elements.map { $0.description }.joined(separator: " ") + ")"
        }
    }

    // debugging flag.
    static let debugging = false
}

// TODO: Error handling must be redesigned.
public enum SExprPNodeError: Swift.Error {
    case malformedExpression(_ reason: String)
}

// SExpressionParser implements an SExpression parser. The initializer takes a String holding an SExpression
// and tokenizes it. The method parseProgramSExpression parses the sequence of tokens and returns the full,
// program-level SExpression.
public struct SExpressionParser {

    private var tokens: [String] // Tokens that make up the SExpression.
    private var index = 0 // Current location in the token array.

    // init creates an SExpressionParser with a string holding SExpression text. It tokenizes the String into an
    // array of tokens.
    public init(_ input: String) {
        self.tokens = SExpressionParser.tokenize(input)
    }

    // tokenArry returns the tokens. This method gives public access to the tokens. It is intended for debugging.
    public func tokenArray() -> [String] {
        self.tokens
    }

    // tokenize tokenizes the initial String into atoms and brackets. This version uses a regular expression
    // that has grown long an unwieldy. TODO: Convert to a hand-crafted lexer.
    private static func tokenize(_ input: String) -> [String] {
        let pattern = #""(?:\\.|[^"])*"\[\d+\]|\(|\)|\{|\}|[^\s(){}"]+\[\d+\]|"(?:\\.|[^"])*"|\[\d+\]|[^\s(){}"]+"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let nsInput = input as NSString
        let matches = regex.matches(in: input, range: NSRange(location: 0, length: nsInput.length))
        return matches.map { nsInput.substring(with: $0.range) }
    }

    // An atom has an optional field that can time them to their original line number in a LifeLines program.
    // This function splits the atom into a (String, Int?) tuple.
    private static func splitAtomAndLine(_ token: String) -> (String, Int?) {
        let regex = try! NSRegularExpression(pattern: #"^(.*)\[(\d+)\]$"#)
        let range = NSRange(location: 0, length: token.utf16.count)
        if let match = regex.firstMatch(in: token, range: range),
           let valueRange = Range(match.range(at: 1), in: token),
           let lineRange = Range(match.range(at: 2), in: token),
           let lineNum = Int(token[lineRange]) {
            let baseValue = String(token[valueRange])
            return (baseValue, lineNum)
        }
        return (token, nil)
    }

    // parseProgramSExpression parses the full SExpression and checks that there are no characters left over.
    // It returns the SExpression it parses. This SExpression must be the .list of the procedure and function
    // definitions and the global declarations that make up the program. This is not checked here, but in the
    // convertToTables function .
    public mutating func parseProgramSExpression() throws -> SExpression {
        let result = try parseSExpression()  // Use the general purpose recursive parser ...
        if index < tokens.count { // ... and then check for left over tokens.
            let extra = tokens[index...].joined(separator: " ")
            throw SExprPNodeError.malformedExpression("Unexpected trailing tokens: \(extra)")
        }
        return result
    }

    // parseSExpression is the general purpose, recursive SExpression parser. It keeps track of the recursive
    // depth of the parse. However the depth is not currently used; its original purpose was to help
    // SExpression description routines to find good places to insert newlies.
    private mutating func parseSExpression(depth: Int = 0) throws -> SExpression {
        guard index < tokens.count else {
            throw SExprPNodeError.malformedExpression("Unexpected end of input")
        }
        let token = tokens[index]
        index += 1

        switch token {
        // Found an opening bracket. SExpressions can mix parentheses and curly brackets.
        case "(", "{":
            let expectedClose = (token == "(") ? ")" : "}"
            var elements: [SExpression] = []
            while index < tokens.count && tokens[index] != expectedClose {
                elements.append(try parseSExpression(depth: depth + 1))
            }
            if index >= tokens.count {
                throw SExprPNodeError.malformedExpression("Missing closing \(expectedClose)")
            }
            index += 1 // consume expectedClose
            return .list(elements)
        // Found a closing bracket.
        case ")", "}":
            throw SExprPNodeError.malformedExpression("Unmatched closing \(token)")

        // Otherwise found an atom that may have an attached line number.
        default:
            let (value, line) = SExpressionParser.splitAtomAndLine(token)
            return .atom(value, line: line)
        }
    }
}

// convertToProgram loads the program SExpression into dictionaries of ProgramNodes. The SExpression is a
// .list whose elements are procedure definitions, function definitions, and/or global variable declarations
// (in any order). This function finds those elements, creates their ProgramNode equivalents, and builds a
// dictionary for each ProgramNode type (.procedureDef, .functionDef, .globalDeclaration). All ProgramNodes are
// created via recursive calls to the toProgramNode routines made from this function.
public func convertToTables(_  program: SExpression) throws -> (procedures: [String: ProgramNode],
                                                        functions: [String: ProgramNode], globals: [String: ProgramValue?] ) {
    var procedures: [String: ProgramNode] = [:] // .procedureDefs found in the program.
    var functions: [String: ProgramNode] = [:]  // .functionDefs found in the program.
    var globals: [String: ProgramValue?] = [:]  // .globalDeclarations found in the program.

    if SExpression.debugging { print("convertToTables called with: \(program)") }
    let commonError = "The program must be a list of procedures, functions, and/or global declarations."

    // The program SExpression is a .list of procedure and function definitions and global declarations,
    // in any order.
    guard case let .list(elements) = program else {
        throw SExprError.syntaxError(commonError)
    }
    // Each element (procedure or function definition, or global declaration) is also a .list.
    for element in elements {
        // Get the list of terms for each element; each has at least two terms.
        guard case let .list(terms) = element, terms.count >= 2 else {
            throw SExprError.syntaxError(commonError)
        }
        // The first term is an .atom ("proc", "func", or "global") that identifies the kind of element.
        guard case let .atom(string, _) = terms[0] else {
            throw SExprError.syntaxError(commonError)
        }
        // Depending on the .atom, handle the three element types.
        switch string {
        // Create a .procedureDef ProgramNode and add it to the procedure table.
        case "proc":
            let procDef = try procedureDefToProgramNode(element)
            guard let (name, _, _) = procDef.asProcedureDef else {
                throw SExprError.syntaxError("Invalid procedure definition: \(element)")
            }
            procedures[name] = procDef
        // Create a .functionDef ProgramNode and add it to the function table.
        case "func":
            let funcDef = try functionDefToProgramNode(element)
            guard let (name, _, _) = funcDef.asFunctionDef else {
                throw SExprError.syntaxError("Invalid function definition: \(element)")
            }
            functions[name] = funcDef

        // Add a global declaration to the global symbol table.
        case "global":
            guard terms.count == 2 else { // TODO: Ignore??
                throw SExprError.syntaxError("Missing global variable name.")
            }
            guard case let .atom(name, _) = terms[1] else {
                throw SExprError.syntaxError("Invalid global variable: \(terms[1])")
            }
            globals[name] = nil
        // Others may be possible in the future, though none anticpated.
        default:
            throw SExprError.syntaxError("Invalid program element SExpression: \(element).")
        }
    }
    return (procedures, functions, globals)
}

// TODO: ERROR HANDLING NEEDS TO BE REDESIGNED.
enum SExprError: Swift.Error {
    case syntaxError(_ message: String)
}

// MARK: Creating ProgramNodes from SExpressions.
// This extension has toProgramNode methods that create ProgramNodes from SExpressions. The routines that toProgramNode
// calls are functions rather than methods.
extension SExpression {

    // toProgramNode is a method that creates ProgramNodes from self. This method handles .atoms directly and
    // calls more specific functions for the .list cases.
    public func toProgramNode() throws -> ProgramNode {
        switch self {
        // The .atom cases are handled directly.
        case .atom(let value, _):
            if let integer = Int(value) {
                return ProgramNode(kind: .integer(integer))
            } else if let double = Double(value) {
                return ProgramNode(kind: .double(double))
            } else if value.starts(with: "\"") && value.hasSuffix("\"") {
                let unquoted = String(value.dropFirst().dropLast()) // Remove quotes.
                return ProgramNode(kind: .string(unquoted))
            } else {
                return ProgramNode(kind: .identifier(value))
            }
        // The .list cases call specific to-ProgramNode functions to create the ProgramNodes.
        case .list(let elements):
            if elements.count == 0 { return ProgramNode(kind: .block(statements: [])) }
            let first = elements[0]
            // The different ProgramNode types are deteremined by the first .atom in the .list.
            switch first {
            case .atom("if", _):       return try ifToProgramNode(elements)
            case .atom("while", _):    return try whileToProgramNode(elements)
            case .atom("return", _):   return try returnToProgramNode(elements)
            case .atom("break", _):    return ProgramNode.breakState()
            case .atom("continue", _): return ProgramNode.continueState()
            case .atom("bltin", _):    return try builtInCallToProgramNode(elements)
            case .atom("call", _):     return try procedureCallToProgramNode(elements)
            case .atom("fcall", _):    return try functionCallToProgramNode(elements)
            default: // .block ProgramNode NOTE: Many other .list types remain to be ported.
                let stmts = try elements.map { try $0.toProgramNode() }
                return ProgramNode(kind: .block(statements: stmts))
            }
        }
    }
}

// ifToProgramNode is the function that creates .ifStatement ProgramNodes from SExpressions.
func ifToProgramNode(_ elements: [SExpression]) throws -> ProgramNode {
    print("ifToProgramNode called")
    precondition(elements.count == 3 || elements.count == 4, "if SExpr must have 3 or 4 elements")
    let cond = try conditionToProgramNode(elements[1])
    let thenc = try elements[2].toProgramNode()
    let elsec = (elements.count == 4) ? try elements[3].toProgramNode() : nil
    let ifnode: ProgramNode = .ifStatement(cond: cond, thenC: thenc, elseC: elsec)
    print("\(ifnode)")
    return ifnode
}

// whileToProgramNode is the function that creates .whileStatement ProgramNodes from SExpressions.
func whileToProgramNode(_ elements: [SExpression]) throws -> ProgramNode {
    precondition(elements.count == 3, "while SExpr must have 3 elements")
    let condition = try conditionToProgramNode(elements[1])
    let body = try elements[2].toProgramNode()
    return ProgramNode.whileStatement(cond: condition, body: body)
}

// conditionToProgramNode is the function that handles conditions in if and while statements.
func conditionToProgramNode(_ condition: SExpression) throws -> [ProgramNode] {
    guard case let .list(elements) = condition else {
        throw SExprPNodeError.malformedExpression("Condition must be list")
    }
    let count = elements.count
    guard count == 1 || count == 2 else {
        throw SExprPNodeError.malformedExpression("Condition must be a list of 1 or 2 elements")
    }
    let exprIndex = count == 1 ? 0 : 1
    let expression = try elements[exprIndex].toProgramNode()
    if count == 1 { return [expression] }
    let ident: ProgramNode = try elements[0].toProgramNode()
    return [ident, expression]
}

// returnToProgramNode is the function that creates .returning ProgramNodes from SExpressions.
func returnToProgramNode(_ elements: [SExpression]) throws -> ProgramNode {
    if elements.count == 1 {
        return ProgramNode.returnState(result: nil)
    } else if elements.count == 2 {
        return try ProgramNode.returnState(result: elements[1].toProgramNode())
    } else {
        throw SExprPNodeError.malformedExpression("return SExpr must have 1 or 2 elements")
    }
}

// builtInCallToProgramNode is the function that creates a .builtinCall ProgramNode from an array of three SExpressions. The
// SExpressions in the array are:  [.atom("bltin"), .atom(name), .list(args)].
func builtInCallToProgramNode(_ elements: [SExpression]) throws -> ProgramNode {
    // Check for three SExpressions.
    guard elements.count == 3 else {
        throw SExprPNodeError.malformedExpression("builtin calls must have three elements.")
    }
    // The second element is the buitin's name.
    guard case let .atom(name, _) = elements[1] else {
        throw SExprPNodeError.malformedExpression("Second element of builtin SExpr must be the name of the builtin")
    }
    // The third element is the list of arguments.
    guard case let .list(args) = elements[2] else {
        throw SExprPNodeError.malformedExpression("Third element of builtin SExpr must be a list of argument expressions")
    }
    // Convert the arguments to ProgramNodes and then create and return the ProgramNode.
    let convertedArgs = try args.map { try $0.toProgramNode() }
    return ProgramNode.builtinCall(name: name, args: convertedArgs)
}

func procedureCallToProgramNode(_ elements: [SExpression]) throws -> ProgramNode {
    guard elements.count == 3 else {
        throw SExprPNodeError.malformedExpression("procedureCallToProgramNode() must have four elements.")
    }
    guard case let .atom(name, _) = elements[1] else {
        throw SExprPNodeError.malformedExpression("Second argument of procedureCallToProgramNode must be the procedure name")
    }
    guard case let .list(args) = elements[2] else {
        throw SExprPNodeError.malformedExpression("Third element of procedureCallToProgramNode must be a list of argument expressions")
    }
    let convertedArgs = try args.map { try $0.toProgramNode() }
    return ProgramNode.procedureCall(name: name, args: convertedArgs)
}

// functionCallToProgramNode creates a .functionCall Program Node from an Array of SExpressions.
func functionCallToProgramNode(_ elements: [SExpression]) throws -> ProgramNode {
    // Elements is an Array of three SExpressions. The second is the function name; the third is the argument list.
    guard elements.count == 3 else {
        throw SExprPNodeError.malformedExpression("functionCallToProgramNode() must have three elements.")
    }
    guard case let .atom(name, _) = elements[1] else {
        throw SExprPNodeError.malformedExpression("Second argument of functionCallToProgramNode must be the function name")
    }
    guard case let .list(args) = elements[2] else {
        throw SExprPNodeError.malformedExpression("Third element of functionCallToProgramNode must be a list of argument expressions")
    }
    // Convert the arguments to ProgramNodes and return a .functionCall ProgramNode.
    let convertedArgs = try args.map { try $0.toProgramNode() }
    return ProgramNode.functionCall(name: name, args: convertedArgs)
}

// procedureDefToProgramNode creates a .procedureDef ProgramNode from a procedure definition SExpression.
func procedureDefToProgramNode(_ procDef: SExpression) throws -> ProgramNode {
    // procDef is a .list of four SExpressions. The second is the procedure name; third is the argument list;
    // fourth is the procedure body.
    guard case let .list(elements) = procDef, elements.count == 4 else {
        throw SExprError.syntaxError("A procedure definition must be a list with four elements.")
    }
    guard case let .atom(nameRaw, _) = elements[1],
          let name = isIdentifier(nameRaw),
          case let .list(params) = elements[2],
          case .list = elements[3] else {
        throw SExprError.syntaxError("Malformed procedure definition SExpression.")
    }
    // Create the parameter list of identifiers.
    let paramStrings = try params.map {
        guard case let .atom(p, _) = $0, let pname = isIdentifier(p) else {
            throw SExprError.syntaxError("Invalid parameter identifier: \($0)")
        }
        return pname
    }
    // Get the ProgramNode form of the procedure body and then return the .procedureDef ProgramNode.
    let body = try elements[3].toProgramNode()
    return ProgramNode.procedureDef(name: name, params: paramStrings, body: body)
}

// functionDefToProgramNode creates a .functionDef ProgramNode from a function definition SExpression.
func functionDefToProgramNode(_ funcDef: SExpression) throws -> ProgramNode {
    // funcDef is a .list of four SExpressions. The second is the function name; third is the argument list;
    // fourth is the function body.
    guard case let .list(elements) = funcDef, elements.count == 4 else {
        throw SExprError.syntaxError("A function definition must be a list with four elements.")
    }
    guard case let .atom(nameRaw, _) = elements[1],
          let name = isIdentifier(nameRaw),
          case let .list(params) = elements[2],
          case .list = elements[3] else {
        throw SExprError.syntaxError("Malformed function definition SExpression.")
    }
    // Create the parameter list of identifiers.
    let paramStrings = try params.map {
        guard case let .atom(p, _) = $0, let pname = isIdentifier(p) else {
            throw SExprError.syntaxError("Invalid parameter identifier: \($0)")
        }
        return pname
    }
    // Get the ProgramNode form of the function body and then return the .functionDef ProgramNode.
    let body = try elements[3].toProgramNode()
    return ProgramNode.functionDef(name: name, params: paramStrings, body: body)
}

// isIdentifier checks whether a String is an identifier.
func isIdentifier(_ string: String) -> String? {
    guard let first = string.first, first.isLetter || first == "_" else {
        return nil
    }
    guard string.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) else {
        return nil
    }
    return string
}
