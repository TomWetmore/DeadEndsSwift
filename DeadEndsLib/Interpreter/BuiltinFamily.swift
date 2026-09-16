//
//  BltinFamily.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 15 September 2026.
//  Last changed on 15 September 2026.
//

import Foundation

extension Program {

    /// Look up a family in the database by its key; the @-signs may be omitted.
    /// family(string|null) -> family|null
    func bltinFamily(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let line = args[0].line
        let value = try await evaluate(args[0])

        if case .null = value {  // Allow null propagation.
            return .null
        }
        guard case let .string(key) = value else {  // If not null arg must be a string.
            throw RuntimeError("person: arg must be a string", line: line)
        }
        let normalized = normalizeGedcomKey(key)
        guard let root = recordIndex[normalized] else {  // If key not in database return null.
            return .null
        }
        guard root.tag == GedcomTag.FAM else {  // If key exists record must be a family.
            throw RuntimeError("person: \(normalized) does not identify a family", line: line)
        }
        return .family(Family(root))
    }

}
