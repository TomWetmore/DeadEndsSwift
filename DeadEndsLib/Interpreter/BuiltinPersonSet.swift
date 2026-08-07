//
//  BuiltinPersonSet.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 17 April 2026.
//  Last changed on 6 August 2026.
//

import Foundation

public typealias ProgramPersonSet = PersonSet<ProgramValue>


extension Program {

    /// Create and return a person set.
    /// personset() -> PersonSet
    func bltinPersonSet(_ args: [ParsedExpr]) throws -> ProgramValue {
        return .personset(ProgramPersonSet())
    }

    /// Add an element to a person set
    /// addtoset(PersonSet, Person[, Any]) -> Null
    func bltinAddToSet(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let personSet = try await evalPersonSet(args[0],
                                                errMsg: "addtoset: 1st arg must be a personset")
        let person = try await evalPerson(args[1],
                                          errMsg: "addtoset: 2nd arg must be a person")
        var any = ProgramValue.null
        if args.count == 3 {
            any = try await evaluate(args[2])
        }
        personSet.append(person, payload: any)
        return .null
    }

    /// Delete an element from an indiseq.
    /// deletefromset(PersonSet, Person) -> Null
    /// the bool is to remove all elements with same person.
    func bltinDeleteFromSet(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let set = try await evalPersonSet(args[0],
                                          errMsg: "deletefromset: 1st arg must be a personset")
        let person = try await evalPerson(args[1],
                                          errMsg: "deletefromset: 2nd arg must be a person")
        set.remove(key: person.key)
        return .null
    }

    /// Sort a person set by name.
    /// namesort(PersonSet) -> Null
    func bltinNameSort(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let setValue = try await evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("namesort: arg must be a personset", line: args[0].line)
        }
        set.nameSort()
        return .null
    }

    /// Sort an person set by key.
    /// keysort(PersonSet) -> Null
    func bltinKeySort(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let setValue = try await evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("keysort: arg must be a personset", line: args[0].line)
        }
        set.keySort()
        return .null
    }

    // Placeholder for valuesort.

    func builtinUniqueset(_ args: [ParsedExpr]) throws -> ProgramValue {
        throw RuntimeError("uniqueset: not implemented", line: args[0].line)
    }
}


///*==========================================
// * uniqueset -- Eliminate dupes from INDISEQ
// *   uniqueset(SET) -> VOID
// *========================================*/
//WORD __uniqueset (node, stab, eflg)
//INTERP node; TABLE stab; BOOLEAN *eflg;
//{
//    INDISEQ seq = (INDISEQ) evaluate(ielist(node), stab, eflg);
//    if (*eflg || !seq) return NULL;
//    return (WORD) unique_indiseq(seq);
//}

/// Set operations
extension Program {

    /// Return the union of two person sets.
    /// union(PersonSet, PersonSet) -> PersonSet
    func bltinUnion(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let set1Value = try await evaluate(args[0])
        guard case let .personset(set1) = set1Value else {
            throw RuntimeError("union: 1st arg must be a personset", line: args[0].line)
        }
        let set2Value = try await evaluate(args[1])
        guard case let .personset(set2) = set2Value else {
            throw RuntimeError("union: 2nd arg must be a personset", line: args[0].line)
        }
        return .personset(set1.unionSet(set2))
    }

    /// Return the intersection of two person sets.
    /// intersect(PersonSet, PersonSet) -> PersonSet
    func bltinIntersect(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let set1Value = try await evaluate(args[0])
        guard case let .personset(set1) = set1Value else {
            throw RuntimeError("intersect: 1st arg must be a personset", line: args[0].line)
        }
        let set2Value = try await evaluate(args[1])
        guard case let .personset(set2) = set2Value else {
            throw RuntimeError("intersect: 2nd arg must be a personset", line: args[1].line)
        }
        return .personset(set1.intersection(set2))
    }

    /// Return the difference of two person sets.
    /// difference(PersonSet, PersonSet) -> PersonSet
    func bltinDifference(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let set1Value = try await evaluate(args[0])
        guard case let .personset(set1) = set1Value else {
            throw RuntimeError("difference: 1st arg must be a personset", line: args[0].line)
        }
        let set2Value = try await evaluate(args[1])
        guard case let .personset(set2) = set2Value else {
            throw RuntimeError("difference: 2nd arg must be a personset", line: args[1].line)
        }
        return .personset(set1.difference(set2))
    }
}

/// Genealogical
extension Program {

    /// Return the parent set of a person set.
    /// parentset(PersonSet) -> PersonSet
    func bltinParentSet(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let setValue = try await evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("parentset: arg must be a personset", line: args[0].line)
        }
        return .personset(set.parentsSet(in: recordIndex))
    }

    /// Return the children set of a person set.
    /// childset(PersonSet) -> PersonSet
    func bltinChildSet(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let setValue = try await evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("childset: arg must be a personset", line: args[0].line)
        }
        return .personset(set.childrenSet(in: recordIndex))
    }

    /// Return the sibling set of a person set.
    /// siblingset(PersonSet) -> PersonSet
    func bltinSiblingSet(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let setValue = try await evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("siblingset: arg must be a personset", line:args[0].line)
        }
        return .personset(set.siblingSet(in: recordIndex))
    }

    /// Return the spouse set of a person set.
    /// spouseset(PersonSet) -> PersonSet
    func bltinSpouseSet(_ args: [ParsedExpr]) async throws -> ProgramValue {
        let setValue = try await evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("spouseset: arg must be a personset", line: args[0].line)
        }
        return .personset(set.spouseSet(in: recordIndex))
    }

    /// Return the ancestor set of a person set.
    /// ancestorset(PersonSet) -> PersonSet
    func bltinAncestorSet(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let setValue = try await evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("ancestorset: arg must be a personset", line: args[0].line)
        }
        return .personset(set.ancestorSet(in: recordIndex))
    }

    /// Return the descendant set of a person set.
    /// descend[a|e]ntset(PersonSet) -> PersonSet
    func bltinDescendentSet(_ args: [ParsedExpr]) async throws -> ProgramValue {

        let setValue = try await evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("descendentset: arg must be a personset", line: args[0].line)
        }
        return .personset(set.descendantSet(in: recordIndex))
    }
}
