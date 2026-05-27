//
//  BuiltinExtract.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 25 May 2026.
//  Last changed on 25 May 2026.
//

import Foundation

extension Program {

    /// Extract parts of a Gedcom name value.
    /// extractnames(node, list, lenVar, surnameIndexVar) -> null
    ///
    /// The first arg may be a NAME node or a node with a NAME child. The second
    /// arg must be a list; it is cleared and filled with string parts. The third
    /// and fourth args must be identifiers that receive the number of parts and
    /// index (relative 1) of the surname; if there is no surnams the value is 0.
    func bltinExtractName(_ args: [ParsedExpr]) async throws -> ProgramValue {

        // 1st arg must resolve to a Gedcom name struct.
        guard let gedcomName = try await evaluateGedcomNameOpt(args[0],
                    errMsg: "extractnames: 1st arg must resolve to a name node") else {
            return .null
        }
        // 2nd arg must be a list.
        guard let list = try await evaluateListOpt(args[1],
                                errMsg: "extractnames: 2nd arg must be a list") else {
            return .null
        }
        list.clear()

        // 3rd arg must be the identifier to hold the list length.
        let lenVar = try requireIdentifier(args[2],
                            errMsg: "extractnames: 3rd arg must be an identifier")
        // 4th arg must be the identifier to hold the surname index or 0.
        let surnameIndexVar = try requireIdentifier(args[3],
                            errMsg: "extractnames: 4th arg must be an identifier")
        list.clear()
        for part in gedcomName.parts {
            list.append(.string(part))
        }
        assignToSymbol(lenVar, value: .integer(gedcomName.parts.count))
        let scriptSurnameIndex = gedcomName.surnameIndex.map { $0 + 1 } ?? 0  // 1-based.
        assignToSymbol(surnameIndexVar, value: .integer(scriptSurnameIndex))
        return .null
    }
}
/// Require a parsed expression to be an .identifier. No evaluation is done.
func requireIdentifier(_ expr: ParsedExpr, errMsg: String) throws -> String {
    guard case let .identifier(name) = expr.kind else {
        throw RuntimeError(errMsg, line: expr.line)
    }
    return name
}

extension Program {
    
    /// Try to get a Gedcom name structure from a variety of possible sources.
    func evaluateGedcomNameOpt(_ expr: ParsedExpr, errMsg: String) async throws -> GedcomName? {
        
        switch try await evaluate(expr) {
        case .person(let person):
            return GedcomName(from: person)
        case .gnode(let node):
            return GedcomName(from: node)
        case .string(let value):
            return GedcomName(string: value)
        case .null:
            return nil
        default:
            throw RuntimeError(errMsg, line: expr.line)
        }
    }
}
