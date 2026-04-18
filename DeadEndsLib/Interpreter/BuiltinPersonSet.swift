//
//  BuiltinPersonSet.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 17 April 2026.
//  Last changed on 17 April 2026.
//

import Foundation

public typealias ProgramPersonSet = PersonSet<ProgramValue>

///*
// * initset -- Initialize list that holds created INDISEQs*/
//initset ()
//{
//    keysets = create_list();
//}

extension Program {

    /// Create a new person set and put it in the symbol table.
    /// indiset(VARB) -> VOID
    func builtinPersonSet(_ args: [ParsedExpr]) throws -> ProgramValue {
        guard case let .identifier(name) = args[0] else {
            throw RuntimeError.typeError("indiset() expects an identifier")
        }
        assignToSymbol(name, value: .indiset(ProgramPersonSet()))
        return .null
    }

    /// Add a an element to a person set
    /// addtoset(SET, INDI, ANY) -> VOID
    func builtinAddtoset(_ args: [ParsedExpr]) throws -> ProgramValue {
        let setValue = try evaluate(args[0])
        guard case let .indiset(set) = setValue else {
            throw RuntimeError.typeError("addtoset() first arg must evaluate to an indiset")
        }
        let indiValue = try evaluateIndi(args[1])
        guard let indi = indiValue else {
            throw RuntimeError.typeError("addtoset() second arg must evaluate to an indi")
        }
        let anyValue = try evaluate(args[2])
        set.append(indi, payload: anyValue)
        return .null
    }

    /// Return length of set as an integer program value.
    /// lengthset(SET) -> INT
    func builtinLengthset(_ args: [ParsedExpr]) throws -> ProgramValue {
        let setValue = try evaluate(args[0])
        guard case let .indiset(set) = setValue else {
            throw RuntimeError.typeError("lengthset() arg must evaluate to an indiset")
        }
        return .integer(set.count)
    }

    /// Delete an element from an indiseq.
    /// deletefromset(SET, INDI, BOOL) -> VOID
    /// the bool is to remove all elements with same person.
    func builtinDeletefromset(_ args: [ParsedExpr]) throws -> ProgramValue {
        let setValue = try evaluate(args[0])
        guard case let .indiset(set) = setValue else {
            throw RuntimeError.typeError("deletefromset() 1st arg must evaluate to an indiset")
        }
        let indiValue = try evaluateIndi(args[1])
        guard let indi = indiValue else {
            throw RuntimeError.typeError("deletefromset() 2nd arg must evaluate to an indi")
        }
        // Ignore third argument.
        // TODO: Come back and worry about this.
        set.remove(key: indi.key!)
        return .null
    }

    /// Sort an indiseq by name.
    /// namesort(SET) -> VOID
    func builtinNamesort(_ args: [ParsedExpr]) throws -> ProgramValue {
        let setValue = try evaluate(args[0])
        guard case let .indiset(set) = setValue else {
            throw RuntimeError.typeError("namesort() arg must evaluate to an indiset")
        }
        set.nameSort()
        return .null
    }

    /// Sort an indiseq by key.
    /// keysort(SET) -> VOID
    func builtinKeysort(_ args: [ParsedExpr]) throws -> ProgramValue {
        let setValue = try evaluate(args[0])
        guard case let .indiset(set) = setValue else {
            throw RuntimeError.typeError("keysort() arg must evaluate to an indiset")
        }
        set.keySort()
        return .null
    }

    // Placeholder for valuesort.

    func builtinUniqueset(_ args: [ParsedExpr]) throws -> ProgramValue {
        throw RuntimeError.typeError("uniqueset() not implemented")
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

    /// Return the union of two indisets.
    /// union(SET, SET) -> SET
    func builtinUnion(_ args: [ParsedExpr]) throws -> ProgramValue {
        let set1Value = try evaluate(args[0])
        guard case let .indiset(set1) = set1Value else {
            throw RuntimeError.typeMismatch("union: 1st arg must evaluate to an indiseq")
        }
        let set2Value = try evaluate(args[1])
        guard case let .indiset(set2) = set2Value else {
            throw RuntimeError.typeMismatch("union: 2nd arg must evaluate to an indiseq")
        }
        return .indiset(set1.union(set2))
    }

    /// Return the intersection of two indisets.
    /// intersect(SET, SET) -> SET
    func builtinIntersect(_ args: [ParsedExpr]) throws -> ProgramValue {
        let set1Value = try evaluate(args[0])
        guard case let .indiset(set1) = set1Value else {
            throw RuntimeError.typeMismatch("intersect: 1st arg must evaluate to an indiset")
        }
        let set2Value = try evaluate(args[1])
        guard case let .indiset(set2) = set2Value else {
            throw RuntimeError.typeMismatch("intersect: 2nd arg must evaluate to an indiset")
        }
        return .indiset(set1.intersection(set2))
    }

    /// Return the difference of two indisets.
    /// difference(SET, SET) -> SET
    func builtinDifference(_ args: [ParsedExpr]) throws -> ProgramValue {
        let set1Value = try evaluate(args[0])
        guard case let .indiset(set1) = set1Value else {
            throw RuntimeError.typeMismatch("difference: 1st arg must evaluate to an indiset")
        }
        let set2Value = try evaluate(args[1])
        guard case let .indiset(set2) = set2Value else {
            throw RuntimeError.typeMismatch("difference: 2nd arg must evaluate to an indiset")
        }
        return .indiset(set1.difference(set2))
    }
}

/// Genealogical
extension Program {

    /// Return the parent set of an indiset.
    /// parentset(SET) -> SET
    func builtinParentset(_ args: [ParsedExpr]) throws -> ProgramValue {
        let setValue = try evaluate(args[0])
        guard case let .indiset(set) = setValue else {
            throw RuntimeError.typeMismatch("parentset: arg must evaluate to an indiset")
        }
        return .indiset(set.parentsSet(in: recordIndex))
    }

    /// Return the children set of an indiset.
    /// childset(SET) -> SET
    func builtinChildset(_ args: [ParsedExpr]) throws -> ProgramValue {
        let setValue = try evaluate(args[0])
        guard case let .indiset(set) = setValue else {
            throw RuntimeError.typeMismatch("childset: arg must evaluate to an indiset")
        }
        return .indiset(set.childrenSet(in: recordIndex))
    }

    /// Return the sibling set of an indiset.
    /// siblingset(SET) -> SET.
    func builtinSiblingset(_ args: [ParsedExpr]) throws -> ProgramValue {
        let setValue = try evaluate(args[0])
        guard case let .indiset(set) = setValue else {
            throw RuntimeError.typeMismatch("siblingset: arg must evaluate to an indiset")
        }
        return .indiset(set.siblingSet(in: recordIndex))
    }

    /// Return the spouse set of an indiset.
    /// spouseset(SET) -> SET.
    func builtinSpouseset(_ args: [ParsedExpr]) throws -> ProgramValue {
        let setValue = try evaluate(args[0])
        guard case let .indiset(set) = setValue else {
            throw RuntimeError.typeMismatch("spouseset: arg must evaluate to an indiset")
        }
        return .indiset(set.spouseSet(in: recordIndex))
    }

    /// Return the ancestor set of an inidset.
    /// ancestorset(SET) -> SET.
    func builtinAncestorset(_ args: [ParsedExpr]) throws -> ProgramValue {
        let setValue = try evaluate(args[0])
        guard case let .indiset(set) = setValue else {
            throw RuntimeError.typeMismatch("ancestorset: arg must evaluate to an indiset")
        }
        return .indiset(set.ancestorSet(in: recordIndex))
    }

    /// Return the descendant set of an indiset.
    /// descend[a|e]ntset(SET) -> SET.
    func builtinDescendentset(_ args: [ParsedExpr]) throws -> ProgramValue {
        let setValue = try evaluate(args[0])
        guard case let .indiset(set) = setValue else {
            throw RuntimeError.typeMismatch("descendentset: arg must evaluate to an indiset")
        }
        return .indiset(set.descendantSet(in: recordIndex))
    }
}

///*====================================================
// * gengedcom -- Generate GEDCOM output from an INDISEQ
// *   gengedcom(SET) -> VOID
// *==================================================*/
//WORD __gengedcom (node, stab, eflg)
//INTERP node; TABLE stab; BOOLEAN *eflg;
//{
//    INDISEQ seq = (INDISEQ) evaluate(ielist(node), stab, eflg);
//    if (*eflg || !seq) return NULL;
//    gen_gedcom(seq);
//    return NULL;
//}
//
