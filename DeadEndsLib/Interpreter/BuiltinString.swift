//
//  BuiltinString.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 12 May 2026.
//  Last changed on 20 May 2026.
//

import Foundation


extension Program {

    /// Compare two strings.
    /// strcmp(STRING, STRING) -> INT
    /// Returns -1, 0, or 1.
    func bltinStrcmp(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let value1 = try await evaluate(args[0])
        guard case let .string(str1) = value1 else {
            throw RuntimeError("strcmp: 1st arg must be a string", line: args[0].line)
        }
        let value2 = try await evaluate(args[1])
        guard case let .string(str2) = value2 else {
            throw RuntimeError("strcmp: second arg must be a string", line: args[1].line)
        }
        switch str1.compare(str2) {
        case .orderedAscending:
            return .integer(-1)
        case .orderedSame:
            return .integer(0)
        case .orderedDescending:
            return .integer(1)
        }
    }
}
