//
//  BuiltinExtract.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 25 May 2026.
//  Last changed on 8 July 2026.
//

import Foundation

extension Program {

    /// This built-in extract parts of a Gedcom name value. The arg may be a
    /// person, a node with a NAME kid, a NAME node itself, or a string.
    /// It returns a pair where first is the list of parts, and second is the
    /// surname index.
    /// extractname(person|node|string) -> pair(list(string), int)
    func bltinExtractName(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let gedcomName = try await evaluateGedcomNameOpt(
            args[0], errMsg: "extractname: arg must find a name"
        )
        if let gedcomName {
            let nameParts = gedcomName.parts.map { ProgramValue.string($0) }
            let partsList = List(nameParts)

            return .pair(Pair(
                .list(partsList),
                .integer(gedcomName.surnameIndex.map { $0 + 1 } ?? 0)
            ))
        }
        return .pair(Pair(.list(List()), .integer(0)))
    }

    /// Built-in that extract the parts from a place string.
    /// extractplace(node|string) -> list(string)
    func bltinExtractPlace(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let value = try await evaluateGedcomPlaceOpt(
            args[0],
            errMsg: "extractplace: arg must find a string"
        )

        switch value {
        case .string(let place):
            let values = extractPlaceParts(place).map(ProgramValue.string)
            return .list(List(values))

        case .null:
            return .list(List())

        default:
            throw RuntimeError("extractplace: arg must find a string", line: args[0].line)
        }
    }
}


extension Program {
    
    /// Get a Gedcom name structure from a variety of sources, including a person,
    /// a NAME gedcom node under a gedcom node, a NAME gedcom node, or a string.
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

    func evaluateGedcomPlaceOpt(_ expr: ParsedExpr, errMsg: String) async throws -> ProgramValue {

        switch try await evaluate(expr) {
        case .gnode(let node):
            if node.tag == GedcomTag.PLAC {
                return node.val.map(ProgramValue.string) ?? .null
            }
            if let plac = node.kid(withTag: GedcomTag.PLAC) {
                return plac.val.map(ProgramValue.string) ?? .null
            }
            return .null
        case .string(let value):
            return .string(value)
        case .null:
            return .null
        default:
            throw RuntimeError(errMsg, line: expr.line)
        }
    }
}

func extractPlaceParts(_ place: String) -> [String] {
    place
        .split(separator: ",", omittingEmptySubsequences: false)
        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
}
