//
//  BuiltinPerson.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 11 April 2026.
//  Last changed on 12 May 2026.
//

import Foundation

/// Name related built-ins.
extension Program {

    // builtinName returns the value of the first 1 NAME line in a person's record.
    // name(person [, bool]). bool for all caps on the surname
    func bltinName(_ args: [ParsedExpr]) throws -> ProgramValue {

        let value = try evaluatePersonOpt(args[0], errMsg: "name: arg must be a person")
        if let person = value {
            return .string(person.displayName(upSurname: false, surnameFirst: false, limit: 0))
        }
        return .null
    }

    /// Returns a person's name with processing.
    /// fullname(person, bool, bool, int) -> string
    func bltinFullName(_ args: [ParsedExpr]) throws -> ProgramValue {

        guard let person = try evaluatePersonOpt(args[0],
                                    errMsg: "fullname: 1st arg must be a person") else {
            return .null
        }
        let upSurname = try evaluate(args[1]).toBool
        let surnameFirst = try evaluate(args[2]).toBool
        let limit = try evaluate(args[3])
        guard case let .integer(intvalue) = limit else {
            throw RuntimeError("fullname: 4th arg must be an integer",
                                line: args[3].line)
        }
        let name = person.displayName(upSurname: upSurname, surnameFirst: surnameFirst,
                                        limit: intvalue)
        return .string(name)

    }

    /// Returns a person's surname as found on the first 1 NAME line in the record.
    func bltinSurname(_ args: [ParsedExpr]) throws -> ProgramValue {

        guard let person = try evaluatePersonOpt(args[0],
                                    errMsg: "surname: arg must be a person") else {
            return .null
        }
        guard let name = person.kidVal(forTag: "NAME") else { return .null }
        guard let gedcomName = GedcomName(string: name) else { return .null }
        guard let surname = gedcomName.surname else { return .null }
        return .string(surname)

    }

    /// Return the given names from the first NAME line in the record.
    /// TODO -- THIS INCLUDES THE SURNAME -- MUST BE FIXED.
    func bltinGivens(_ args: [ParsedExpr]) throws -> ProgramValue {

        guard let person = try evaluatePersonOpt(args[0],
                                    errMsg: "givens: arg must be a person") else {
            return .null
        }
        guard let name = person.kidVal(forTag: "NAME") else { return .null }
        guard let gedcomName = GedcomName(string: name) else { return .null }
        return .string(gedcomName.parts.joined(separator: " "))

    }

    /// Returns the trimmed name of a person.
    /// TODO: SHOULDN'T THIS HAVE A SECOND PARAMETER TO SET THE TRIM LENGTH?
    func builtinTrimName(_ args: [ParsedExpr]) throws -> ProgramValue {

        guard let person = try evaluatePersonOpt(args[0],
                                    errMsg: "trimName: arg must be a person") else {
            return .null
        }
        return .string(person.displayName(limit: 40))
    }
}

/// Relationship reated built-ins.
extension Program {

    /// Return the next sibling of a person.
    /// nextsibling(person) -> .person or .null
    func builtinNextSibling(_ args: [ParsedExpr]) throws -> ProgramValue {

        guard let person = try evaluatePersonOpt(args[0],
                                           errMsg: "nextsib: arg must be a person") else {
            return .null
        }
        if let nextSibling = person.nextSibling(in: self.recordIndex) {
            return .person(nextSibling)
        } else {
            return .null
        }
    }

    /// Return the previous sibling of a person.
    func builtinPrevSibling(_ args: [ParsedExpr]) throws -> ProgramValue {

        guard let person = try evaluatePersonOpt(args[0],
                                    errMsg: "prevsib: arg must be a person") else {
            return .null
        }
        if let previousSibling = person.previousSibling(in: self.recordIndex) {
            return .person(previousSibling)
        } else {
            return .null
        }
    }

    /// Return the first father of a person.
    func bltinFather(_ args: [ParsedExpr]) throws -> ProgramValue {

        let person = try evaluatePersonOpt(args[0], errMsg: "father: arg must be a person")
        guard let father = person?.father(in: self.recordIndex) else {
            return .null
        }
        return .person(father)
    }

    /// Return the first mother of a person.
    func bltinMother(_ args: [ParsedExpr]) throws -> ProgramValue {

        let person = try evaluatePersonOpt(args[0], errMsg: "mother: arg must be a person")
        guard let mother = person?.mother(in: self.recordIndex) else {
            return .null
        }
        return .person(mother)
    }

    /// Made generic so it can run on persons and families.
    func bltinHusband(_ args: [ParsedExpr]) throws -> ProgramValue {
        
        let value = try evaluate(args[0])
        switch value {
        case .person(let person):
            return person.husband(in: recordIndex).map { .person($0) } ?? .null
        case .family(let family):
            return family.husband(in: recordIndex).map { .person($0) } ?? .null
        case .null:
            return .null
        default:
            throw RuntimeError("husband: arg must be a person or family",
                               line: args[0].line)
        }
    }

    /// Made generic so it can run on persons and families.
    func bltinWife(_ args: [ParsedExpr]) throws -> ProgramValue {

        let value = try evaluate(args[0])
        switch value {
        case .person(let person):
            return person.wife(in: recordIndex).map { .person($0) } ?? .null
        case .family(let family):
            return family.wife(in: recordIndex).map { .person($0) } ?? .null
        case .null:
            return .null
        default:
            throw RuntimeError("wife: arg must be a person or family",
                               line: args[0].line)
        }
    }
}

/// Sex and role related built-ins.
extension Program {

    func builtinSex(_ args: [ParsedExpr]) throws -> ProgramValue {
        print("TODO: builtinSex not implemented")
        return .null
    }

    /// Return true if a person is male.
    func bltinMale(_ args: [ParsedExpr]) throws -> ProgramValue {

        guard let person = try evaluatePersonOpt(args[0],
                                errMsg: "male: arg must be a person") else { return .null }
        return person.isMale ? ProgramValue.trueProgramValue : ProgramValue.falseProgramValue
    }

    /// Return true if a person is female.
    func bltinFemale(_ args: [ParsedExpr]) throws -> ProgramValue {

        guard let person = try evaluatePersonOpt(args[0],
                                errMsg: "female: arg must be a person") else { return .null }
        return person.isFemale ? ProgramValue.trueProgramValue
            : ProgramValue.falseProgramValue
    }

    func builtinPronouns(_ args: [ParsedExpr]) throws -> ProgramValue {
        print("builtInPronouns not implemented")
        return .null
    }
}

extension Program {

    func builtinNSpouses(_ args: [ParsedExpr]) throws -> ProgramValue {
        print("builtinNSpouses not implemented")
        return .null
    }

    func builtinNFamilies(_ args: [ParsedExpr]) throws -> ProgramValue {
        print("builtinNFamilies not implemented")
        return .null
    }

    func builtinTitle(_ args: [ParsedExpr]) throws -> ProgramValue {
        print("builtinTitle not implemented")
        return .null
    }

    /// Return the key of a record or a root node.
    /// TODO: Extend to the other record types.
    func bltinKey(_ args: [ParsedExpr]) throws -> ProgramValue {

        let line = args[0].line
        let value = try evaluate(args[0])
        let node: GedcomNode

        switch value {
        case .person(let person):
            node = person.root
        case .family(let family):
            node = family.root
        case .null:
            return .null
        case .gnode(let gnode):
            node = gnode
        default:
            throw RuntimeError("key: arg must be a record or root node", line: line)
        }
        guard let key = node.key else {
            throw RuntimeError("key: arg must be a record or root node", line: line)
        }
        return .string(key)
    }

    func builtinSoundex(_ args: [ParsedExpr]) throws -> ProgramValue {
        print("builtinSoundes not implemented")
        return .null
    }

    /// Buitin that returns the root node of a record.
    /// TODO: Extend to the other record types.
    func bltinRoot(_ args: [ParsedExpr]) throws -> ProgramValue {

        let line = args[0].line
        let value = try evaluate(args[0])
        switch value {
        case .person(let person):
            return .gnode(person.root)
        case .family(let family):
            return .gnode(family.root)
        case .null:
            return .null
        default:
            throw RuntimeError("root: arg must be a person or family", line: line)
        }
    }

    /// Look up a person in the database by its key; the @-signs may be omitted.
    func bltinPerson(_ args: [ParsedExpr]) throws -> ProgramValue {

        let line = args[0].line
        let value = try evaluate(args[0])
        guard case let .string(key) = value else {
            throw RuntimeError("indi: arg must be a person key", line: line)
        }
        let normalized = normalizeGedcomKey(key)
        guard let root = recordIndex[normalized], root.tag == GedcomTag.INDI else {
            throw RuntimeError("indi: arg must be a person key", line: line)
        }
        return .person(Person(root))
    }

    /// Normalize a key (add @-signs if not present).
    private func normalizeGedcomKey(_ key: String) -> String {
        var k = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if !k.hasPrefix("@") { k = "@" + k }
        if !k.hasSuffix("@") { k = k + "@" }
        return k
    }

    func builtinFirstIndi(_ args: [ParsedExpr]) throws -> ProgramValue {
        print("builtinFirstIndi not implemented")
        return .null
    }

    func builtinNextIndi(_ args: [ParsedExpr]) throws -> ProgramValue {
        print("builtinNextIndi not implemented")
        return .null
    }

    func builtinPrevIndi(_ args: [ParsedExpr]) throws -> ProgramValue {
        print("builtinPrevIndi not implemented")
        return .null
    }

    /// Return the all persons program value.
    func bltinAllPersons(_ args: [ParsedExpr]) throws -> ProgramValue {
        return .allPersons
    }

    /// Return the all families program value.
    func bltinAllFamilies(_ args: [ParsedExpr]) throws -> ProgramValue {
        return .allFamilies
    }
}


extension Program {

    // Extract an event from a .gnode associated ProgramNode.
    func extractPersonEvent(from arg: ParsedExpr, tag: String, functionName: String) throws -> ProgramValue {
//        // Get the person with the requested event.
//        let person = try personFromProgramNode(arg, errorMessage: "\(functionName)() expects a person root node")
//        // Get the first child node with the even's tag in the person's tree.
//        return person.kid(withTag: tag).map { .gnode($0) } ?? .null

        return .null
    }
}


/*
 -----------------------------------
 STRING name(INDI [,BOOL])
 STRING fullname(INDI, BOOL, BOOL, INT)
 STRING surname(INDI)
 STRING givens(INDI)
 STRING trimname(INDI,INT)

 default name of
 many name forms of
 surname of
 given names of
 trimmed name of
 -----------------------------------
 EVENT birth(INDI)
 EVENT death(INDI)
 EVENT baptism(INDI)
 EVENT burial(INDI)

 first birth event of
 first death event of
 first baptism event of
 first burial event of
 -----------------------------------
 STRING sex(INDI)
 BOOL male(INDI)
 BOOL female(INDI)
 STRING pn(INDI, INT)

 sex of
 male predicate
 female predicate
 pronoun referring to
 -----------------------------------
 INT nspouses(INDI)
 INT nfamilies(INDI)
 FAM parents(INDI)

 number of spouses of
 number of families (as spouse/parent) of
 first parents’ family of
-----------------------------------
 STRING title(INDI)
 STRING key(INDI|FAM [,BOOL])
 STRING soundex(INDI)
 NODE inode(INDI)
 NODE root(INDI)
 
 first title of
 internal key of (work for families also)
 SOUNDEX code of
 root GEDCOM node of
 root GEDCOM node of
 -----------------------------------
 INDI firstindi()
 INDI nextindi(INDI)
 INDI previndi(INDI)

 first person in database in key order
 next person in database in key order
 previous person in database in key order
 -----------------------------------
 */
