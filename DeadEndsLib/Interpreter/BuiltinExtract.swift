//
//  BuiltinExtract.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 25 May 2026.
//  Last changed on 14 October 2026.
//

import Foundation

extension Program {

    /// Extract the parts of a Gedcom name value. The arg may be a Person, a GedcomNode
    /// with a NAME kid, a NAME node itself, or a String. It returns a .pair ProgramValue
    /// where the first component is the .list of the parts, and the second is the .integer
    /// index of the surname among the parts.
    /// extractname(person|node|string) -> pair(list<string>, int)
    ///
    func bltinExtractName(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let gedcomName = try await evaluateGedcomNameOpt(
            args[0], errMsg: "extractname: arg must find a name"
        )
        if let gedcomName {
            let nameParts = gedcomName.parts.map { ProgramValue.string($0) }
            let partsList = ListValue(nameParts)

            return .pair(Pair(
                .list(partsList),
                .integer(gedcomName.surnameIndex.map { $0 + 1 } ?? 0)
            ))
        }
        return .pair(Pair(.emptyList, .integer(0)))
    }

    /// Extract the parts of a place string.
    /// extractplace(node|string) -> list<string>
    ///
    func bltinExtractPlace(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let value = try await evaluateGedcomPlaceOpt(args[0],
                                    errMsg: "extractplace: arg must find a string")

        switch value {

        // If it is a string break it into a .list of parts.
        case .string(let place):
            let values = extractPlaceParts(place).map(ProgramValue.string)
            return .list(ListValue(values))

        // Support null forwarding.
        case .null:
            return .emptyList

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

    /// Evaluate a ParsedExpr looking for a place value; return the value as a .string
    ///
    func evaluateGedcomPlaceOpt(_ expr: ParsedExpr, errMsg: String)
            async throws -> ProgramValue {

        switch try await evaluate(expr) {

        // If the expression is a GedcomNode is must be a PLAC node or the dad of a PLAC node.
        case .gnode(let node):
            if node.tag == GedcomTag.PLAC {
                return node.val.map(ProgramValue.string) ?? .null
            }
            if let plac = node.kid(withTag: GedcomTag.PLAC) {
                return plac.val.map(ProgramValue.string) ?? .null
            }
            return .null // TODO: Should this throw a RuntimeError?

        // If the expression is a string use it as is as the place value.
        case .string(let value):
            return .string(value)

        // Null forwarding supported.
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
