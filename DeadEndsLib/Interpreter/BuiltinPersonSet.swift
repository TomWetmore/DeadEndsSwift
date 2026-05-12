//
//  BuiltinPersonSet.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 17 April 2026.
//  Last changed on 12 May 2026.
//

import Foundation

public typealias ProgramPersonSet = PersonSet<ProgramValue>


extension Program {

    /// Create a new person set and put it in the symbol table.
    /// personset() -> PersonSet
    func bltinPersonSet(_ args: [ParsedExpr]) throws -> ProgramValue {
        return .personset(ProgramPersonSet())
    }

    /// Add an element to a person set
    /// addtoset(PersonSet, Person, Any) -> Void
    func bltinAddToSet(_ args: [ParsedExpr]) throws -> ProgramValue {
        let personSet = try evalPersonSet(args[0], errMsg: "addtoset: 1st arg must be a personset")
        let person = try evaluatePerson(args[1], errMsg: "addtoset: 2nd arg must be a person")
        var any = ProgramValue.null
        if args.count == 3 {
            any = try evaluate(args[2])
        }
        personSet.append(person, payload: any)
        return .null
    }

    /// Delete an element from an indiseq.
    /// deletefromset(PersonSet, Person) -> Void
    /// the bool is to remove all elements with same person.
    func bltinDeleteFromSet(_ args: [ParsedExpr]) throws -> ProgramValue {
        let set = try evalPersonSet(args[0], errMsg: "deletefromset: 1st arg must be a personset")
        let person = try evaluatePerson(args[1], errMsg: "deletefromset: 2nd arg must be a person")
        set.remove(key: person.key)
        return .null
    }

    /// Sort a person set by name.
    /// namesort(PersonSet) -> Void
    func bltinNameSort(_ args: [ParsedExpr]) throws -> ProgramValue {
        let setValue = try evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("namesort: arg must be a personset", line: args[0].line)
        }
        set.nameSort()
        return .null
    }

    /// Sort an indiseq by key.
    /// keysort(SET) -> VOID
    func bltinKeySort(_ args: [ParsedExpr]) throws -> ProgramValue {
        let setValue = try evaluate(args[0])
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

    /// Return the union of two personsets.
    /// union(SET, SET) -> SET
    func bltinUnion(_ args: [ParsedExpr]) throws -> ProgramValue {
        let set1Value = try evaluate(args[0])
        guard case let .personset(set1) = set1Value else {
            throw RuntimeError("union: 1st arg must be a personset", line: args[0].line)
        }
        let set2Value = try evaluate(args[1])
        guard case let .personset(set2) = set2Value else {
            throw RuntimeError("union: 2nd arg must be a personset", line: args[0].line)
        }
        return .personset(set1.unionSet(set2))
    }

    /// Return the intersection of two personsets.
    /// intersect(SET, SET) -> SET
    func bltinIntersect(_ args: [ParsedExpr]) throws -> ProgramValue {
        let set1Value = try evaluate(args[0])
        guard case let .personset(set1) = set1Value else {
            throw RuntimeError("intersect: 1st arg must be a personset", line: args[0].line)
        }
        let set2Value = try evaluate(args[1])
        guard case let .personset(set2) = set2Value else {
            throw RuntimeError("intersect: 2nd arg must be a personset", line: args[1].line)
        }
        return .personset(set1.intersection(set2))
    }

    /// Return the difference of two personsets.
    /// difference(SET, SET) -> SET
    func bltinDifference(_ args: [ParsedExpr]) throws -> ProgramValue {
        let set1Value = try evaluate(args[0])
        guard case let .personset(set1) = set1Value else {
            throw RuntimeError("difference: 1st arg must be a personset", line: args[0].line)
        }
        let set2Value = try evaluate(args[1])
        guard case let .personset(set2) = set2Value else {
            throw RuntimeError("difference: 2nd arg must be a personset", line: args[1].line)
        }
        return .personset(set1.difference(set2))
    }
}

/// Genealogical
extension Program {

    /// Return the parent set of a personset.
    /// parentset(SET) -> SET
    func bltinParentSet(_ args: [ParsedExpr]) throws -> ProgramValue {
        let setValue = try evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("parentset: arg must be a personset", line: args[0].line)
        }
        return .personset(set.parentsSet(in: recordIndex))
    }

    /// Return the children set of a personset.
    /// childset(SET) -> SET
    func bltinChildSet(_ args: [ParsedExpr]) throws -> ProgramValue {
        let setValue = try evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("childset: arg must be a personset", line: args[0].line)
        }
        return .personset(set.childrenSet(in: recordIndex))
    }

    /// Return the sibling set of a personset.
    /// siblingset(SET) -> SET.
    func bltinSiblingSet(_ args: [ParsedExpr]) throws -> ProgramValue {
        let setValue = try evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("siblingset: arg must be a personset", line:args[0].line)
        }
        return .personset(set.siblingSet(in: recordIndex))
    }

    /// Return the spouse set of a personset.
    /// spouseset(SET) -> SET.
    func bltinSpouseSet(_ args: [ParsedExpr]) throws -> ProgramValue {
        let setValue = try evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("spouseset: arg must be a personset", line: args[0].line)
        }
        return .personset(set.spouseSet(in: recordIndex))
    }

    /// Return the ancestor set of a personset.
    /// ancestorset(SET) -> SET.
    func bltinAncestorSet(_ args: [ParsedExpr]) throws -> ProgramValue {
        let setValue = try evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("ancestorset: arg must be a personset", line: args[0].line)
        }
        return .personset(set.ancestorSet(in: recordIndex))
    }

    /// Return the descendant set of a personset.
    /// descend[a|e]ntset(SET) -> SET.
    func bltinDescendentSet(_ args: [ParsedExpr]) throws -> ProgramValue {
        let setValue = try evaluate(args[0])
        guard case let .personset(set) = setValue else {
            throw RuntimeError("descendentset: arg must be a personset", line: args[0].line)
        }
        return .personset(set.descendantSet(in: recordIndex))
    }
}
