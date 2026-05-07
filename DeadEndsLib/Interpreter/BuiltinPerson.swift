//
//  BuiltinPerson.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 11 April 2026.
//  Last changed on 5 May 2026.
//

import Foundation

/// Name related built-ins.
extension Program {

    // builtinName returns the value of the first 1 NAME line in a person's record.
    func builtinName(_ args: [ParsedExpr]) throws -> ProgramValue {

        let person = try evaluatePerson(args[0], errMessage: "name: arg must be a person")
        guard let name = person.kidVal(forTag: "NAME") else { return .null }
        return .string(name)
    }

    func builtinFullName(_ args: [ProgramNode]) throws -> ProgramValue {
        print("builtinFullName not implemented")
        return .null
    }

    // builtinSurname returns the surname found on the first NAME line in a person' record.
    func builtinSurname(_ arg: [ParsedExpr]) throws -> ProgramValue {

        let person = try evaluatePerson(arg[0], errMessage: "surname: arg must be a person")
        guard let name = person.kidVal(forTag: "NAME") else { return .null }
        guard let gedcomName = GedcomName(string: name) else { return .null }
        guard let surname = gedcomName.surname else { return .null }
        return .string(surname)
    }

    // builtinGivens returns the given names ...
    func builtinGivens(_ arg: [ParsedExpr]) throws -> ProgramValue {

        let person = try evaluatePerson(arg[0], errMessage: "givens: arg must be a person")
        guard let name = person.kidVal(forTag: "NAME") else { return .null }
        guard let gedcomName = GedcomName(string: name) else { return .null }
        return .string(gedcomName.parts.joined(separator: " "))
    }

    /// Returns the trimmed name of a persons.
    func builtinTrimName(_ args: [ParsedExpr]) throws -> ProgramValue {

        let person = try evaluatePerson(args[0], errMessage: "trimName: arg must be a person")
        return .string(person.displayName(limit: 40))  // TODO: Get the length from the args.
    }
}

/// Event realted built-ins.
extension Program {

    /// Returns the first birth event of a person.
    func builtinBirth(_ args: [ParsedExpr]) throws -> ProgramValue {
        let person = try evaluatePerson(args[0], errMessage: "birth: arg must be a person")
        guard let birth = person.kid(withTag: GedcomTag.BIRT) else { return .null }
        return .gnode(birth)
    }

    /// Returns the first death event of a person
    func builtinDeath(_ args: [ParsedExpr]) throws -> ProgramValue {
        let person = try evaluatePerson(args[0], errMessage: "death: arg must be a person")
        guard let birth = person.kid(withTag: GedcomTag.DEAT) else { return .null }
        return .gnode(birth)
    }

    /// Return the first burial event of a person.
    func builtinBurial(_ args: [ParsedExpr]) throws -> ProgramValue {
        let person = try evaluatePerson(args[0], errMessage: "burial: arg must be a person")
        guard let birth = person.kid(withTag: GedcomTag.BURI) else { return .null }
        return .gnode(birth)    }

    /// Return the first baptims event of a person.
    func builtinBaptism(_ args: [ParsedExpr]) throws -> ProgramValue {
        return try extractPersonEvent(from: args[0], tag: "BAPM", functionName: "baptism")
    }
}

/// Relationship reated built-ins.
extension Program {

    /// Return the first father of a person.
//    func builtinFather(_ args: [ParsedExpr]) throws -> ProgramValue {
//
//        let person = try evaluatePerson(args[0], errMessage: "father: arg must be a person")
//        if let father = person.father(in: self.recordIndex) {
//            return .person(father)
//        } else {
//            return .null
//        }
//    }
//
//    /// Return the first mother of a person.
//    func builtinMother(_ args: [ParsedExpr]) throws -> ProgramValue {
//
//        let person = try evaluatePerson(args[0], errMessage: "mother: arg must be a person.")
//        if let mother = person.mother(in: self.recordIndex) {
//            return .person(mother)
//        } else {
//            return .null
//        }
//    }

    /// Return the next sibling of a person.
    func builtinNextSibling(_ args: [ParsedExpr]) throws -> ProgramValue {

        let person = try evaluatePerson(args[0], errMessage: "nextsib: arg must be a person")
        if let nextSibling = person.nextSibling(in: self.recordIndex) {
            return .person(nextSibling)
        } else {
            return .null
        }
    }

    /// Return the previous sibling of a person.
    func builtinPrevSibling(_ args: [ParsedExpr]) throws -> ProgramValue {

        let person = try evaluatePerson(args[0], errMessage: "prevsib: arg must be a person")
        if let previousSibling = person.previousSibling(in: self.recordIndex) {
            return .person(previousSibling)
        } else {
            return .null
        }
    }

    func builtinFather(_ args: [ParsedExpr]) throws -> ProgramValue {

        let person = try evaluatePersonOpt(args[0], errMessage: "father: arg must be a person")
        guard let father = person?.father(in: self.recordIndex) else {
            return .null
        }
        return .person(father)
    }

    func builtinMother(_ args: [ParsedExpr]) throws -> ProgramValue {

        let person = try evaluatePersonOpt(args[0], errMessage: "mother: arg must be a person")
        guard let mother = person?.mother(in: self.recordIndex) else {
            return .null
        }
        return .person(mother)
    }

    /// Make it generic so it can run on persons and families.
    func builtinHusband(_ args: [ParsedExpr]) throws -> ProgramValue {
        
        let value = try evaluate(args[0])
        switch value {
        case .person(let person):
            return person.husband(in: recordIndex).map { .person($0) } ?? .null
        case .family(let family):
            return family.husband(in: recordIndex).map { .person($0) } ?? .null
        case .null:
            return .null
        default:
            throw RuntimeError.typeMismatch(
                "husband: arg must be a person or family",
                line: args[0].line
            )
        }
    }

    /// Make it generic so it can run on persons and families.
    func builtinWife(_ args: [ParsedExpr]) throws -> ProgramValue {

        let value = try evaluate(args[0])
        switch value {
        case .person(let person):
            return person.wife(in: recordIndex).map { .person($0) } ?? .null
        case .family(let family):
            return family.wife(in: recordIndex).map { .person($0) } ?? .null
        case .null:
            return .null
        default:
            throw RuntimeError.typeMismatch(
                "wife: arg must be a person or family",
                line: args[0].line
            )
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
    func builtinMale(_ args: [ParsedExpr]) throws -> ProgramValue {

        let person = try evaluatePerson(args[0], errMessage: "male: arg must be a person")
        return person.isMale ? ProgramValue.trueProgramValue : ProgramValue.falseProgramValue
    }

    /// Return true if a person is female.
    func builtinFemale(_ args: [ParsedExpr]) throws -> ProgramValue {

        let person = try evaluatePerson(args[0], errMessage: "female: arg must be a person")
        return person.isFemale ?
        ProgramValue.trueProgramValue : ProgramValue.falseProgramValue
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

    func builtinParents(_ args: [ParsedExpr]) throws -> ProgramValue {
        print("builtinParents not implemented")
        return .null
    }

    func builtinTitle(_ args: [ParsedExpr]) throws -> ProgramValue {
        print("builtinTitle not implemented")
        return .null
    }

    // THIS ALSO WORKS FOR FAMIIES
    func builtinKey(_ args: [ParsedExpr]) throws -> ProgramValue {
        print("builtinKey not implemented")
        return .null
    }

    func builtinSoundex(_ args: [ParsedExpr]) throws -> ProgramValue {
        print("builtinSoundes not implemented")
        return .null
    }

    func builtinRoot(_ args: [ParsedExpr]) throws -> ProgramValue {
        print("builtinRoot not implemented")
        return .null
    }

    /// Look up a person in the database by its key; the @-signs may be omitted.
    func builtinIndi(_ args: [ParsedExpr]) throws -> ProgramValue {

        let line = args[0].line
        let value = try evaluate(args[0])
        guard case let .string(key) = value else {
            throw RuntimeError.invalidArguments("indi: arg must be a person key", line: line)
        }
        let normalized = normalizeGedcomKey(key)
        guard let root = recordIndex[normalized], root.tag == GedcomTag.INDI else {
            throw RuntimeError.invalidArguments("indi: arg must be a person key", line: line)
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

    

}

extension Program {

    func builtinDate(_ arg: [ParsedExpr]) throws -> ProgramValue {
        let node = try evaluateGedcomNodeOpt(arg[0], errMessage: "date: arg must be a node")
        if let node = node, let date = node.kid(withTag: GedcomTag.DATE) {
            return .gnode(date)
        }
        return .null
    }

    func builtinPlace(_ arg: [ParsedExpr]) throws -> ProgramValue {
        let node = try evaluateGedcomNodeOpt(arg[0], errMessage: "place: arg must be a node")
        if let node = node, let place = node.kid(withTag: GedcomTag.PLAC) {
            return .gnode(place)
        }
        return .null
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
 INDI father(INDI)
 INDI mother(INDI)
 INDI nextsib(INDI)
 INDI prevsib(INDI)

 first father of
 first mother of
 next (younger) sibling of
 previous (older) sibling of
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
 INDI indi(STRING)

 find person with key value
 -----------------------------------
 INDI firstindi()
 INDI nextindi(INDI)
 INDI previndi(INDI)

 first person in database in key order
 next person in database in key order
 previous person in database in key order
 -----------------------------------
 spouses (INDI, INDI, FAM, INT) { }
 families (INDI, FAM, INDI, INT) { }
 forindi (INDI, INT) { }

 loop through all spouses of
 loop through all families (as spouse) of
 loop through all persons in database
 -----------------------------------
 */
