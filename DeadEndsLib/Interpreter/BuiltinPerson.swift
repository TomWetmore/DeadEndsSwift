//
//  BuiltinPerson.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 11 April 2026.
//  Last changed on 26 April 2026.
//

import Foundation

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
        guard let person = try evaluateIndi(arg[0]) else {
            throw RuntimeError.typeError("surname() expects a person parameter",
                                         line: arg[0].line)
        }
        guard let name = person.kidVal(forTag: "NAME") else { return .null }
        guard let gedcomName = GedcomName(string: name) else { return .null }
        guard let surname = gedcomName.surname else { return .null }
        return .string(surname)
    }

    // builtinGivens returns the given names ...
    func builtinGivens(_ arg: [ParsedExpr]) throws -> ProgramValue {
        guard let person = try evaluateIndi(arg[0]) else {
            throw RuntimeError.typeError("givens() expects a person parameter",
                                         line: arg[0].line)
        }
        guard let name = person.kidVal(forTag: "NAME") else { return .null }
        guard let gedcomName = GedcomName(string: name) else { return .null }
        return .string(gedcomName.parts.joined(separator: " "))
    }

    func builtinTrimName(_ args: [ParsedExpr]) throws -> ProgramValue {
        // Get the person whose name is to be trimmed.
        let person = try personFromParsedExpr(args[0], errorMessage: "trimName() expects a person argument");
        // Get the trim length.
        person.displayName(limit: 40) // figure out what it should be.
        print("builtinTrimName not implemented")
        return .null
    }

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

    /// Returns the first burial event of a person.
    func builtinBurial(_ args: [ParsedExpr]) throws -> ProgramValue {
        let person = try evaluatePerson(args[0], errMessage: "burial: arg must be a person")
        guard let birth = person.kid(withTag: GedcomTag.BURI) else { return .null }
        return .gnode(birth)    }

    /// Returns the first baptims event of a person.
    func builtinBaptism(_ args: [ParsedExpr]) throws -> ProgramValue {
        return try extractPersonEvent(from: args[0], tag: "BAPM", functionName: "baptism")
    }

    /// Returns the first father of a person.
    func builtinFather(_ args: [ParsedExpr]) throws -> ProgramValue {

        let person = try personFromParsedExpr(args[0], errorMessage: "father: arg must be a person")
        if let father = person.father(in: self.recordIndex) {
            return .person(father)
        } else {
            return .null
        }
    }

    // builtinMother is the buitin function that returns a person's mother.
    func builtinMother(_ args: [ParsedExpr]) throws -> ProgramValue {
        // Get the person whose mother is to be found.
        let person = try personFromParsedExpr(args[0], errorMessage: "mother: arg must be a person.")
        // Get the person's mother.
        if let mother = person.mother(in: self.recordIndex) {
            return .person(mother)
        } else {
            return .null
        }
    }

    // builtinNextSibling ...
    func builtinNextSibling(_ args: [ParsedExpr]) throws -> ProgramValue {
        // Get the person whose next sibling is needed.
        let person = try personFromParsedExpr(args[0], errorMessage: "nextsib() expects a person argument")
        // Get the next sibling of the person.
        if let nextSibling = person.nextSibling(in: self.recordIndex) {
            return .person(nextSibling)
        } else {
            return .null
        }
    }

    func builtinPrevSibling(_ args: [ParsedExpr]) throws -> ProgramValue {
        // Get the person whose previous sibling is needed.
        let person = try personFromParsedExpr(args[0], errorMessage: "prevsib() expects a person argument")
        // Get the previous sibling of the person.
        if let previousSibling = person.previousSibling(in: self.recordIndex) {
            return .person(previousSibling)
        } else {
            return .null
        }
    }

    func builtinSex(_ args: [ParsedExpr]) throws -> ProgramValue {
        print("builtinSex not implemented")
        return .null
    }

    func builtinMale(_ args: [ParsedExpr]) throws -> ProgramValue {
        // Get the person to be checked for being male.
        let person = try personFromParsedExpr(args[0], errorMessage: "male() expects a person argument")
        return person.isMale ? ProgramValue.trueProgramValue : ProgramValue.falseProgramValue
    }

    func builtinFemale(_ args: [ParsedExpr]) throws -> ProgramValue {
        // Get the person to be checked for being female.
        let person = try personFromParsedExpr(args[0], errorMessage: "female() expects a person argument")
        return person.isFemale ? ProgramValue.trueProgramValue : ProgramValue.falseProgramValue
    }

    func builtinPronouns(_ args: [ParsedExpr]) throws -> ProgramValue {
        print("builtInPronouns not implemented")
        return .null
    }

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

    func builtinINode(_ args: [ParsedExpr]) throws -> ProgramValue {
        print("builtinINode not implemented")
        return .null
    }

    func builtinRoot(_ args: [ParsedExpr]) throws -> ProgramValue {
        print("builtinRoot not implemented")
        return .null
    }

    /// Look up a person in the database and return its root.
//    func builtinIndi(_ args: [ParsedExpr]) throws -> ProgramValue {
//        let key = try evaluate(args[0])
//        guard case let .string(key) = key, let node = recordIndex[key],
//              node.tag == GedcomTag.INDI
//        else { return .null }
//        return .gnode(node)
//    }

    /// Look up a person in the database.
    /// Look up a person in the database.
    func builtinIndi(_ args: [ParsedExpr]) throws -> ProgramValue {

        let value = try evaluate(args[0])
        guard case let .string(key) = value, let root = recordIndex[key],
              root.tag == GedcomTag.INDI
        else {
            return .null
        }
        return .person(Person(root))
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

    //spouses (INDI, INDI, FAM, INT) { }
    //loop through all spouses of
    //
    //families (INDI, FAM, INDI, INT) { }
    //loop through all families (as spouse) of
    //
    //forindi (INDI, INT) { }
    //loop through all persons in database

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

    /// Evaluates a parsed expression that should be a person.
    func personFromParsedExpr(_ expr: ParsedExpr, errorMessage: String) throws -> Person {
        let value = try evaluate(expr)
        guard case let .person(person) = value, person.tag == GedcomTag.INDI else {
            throw RuntimeError.typeError(errorMessage, line: expr.line)
        }
        return person
    }

    // Extract an event from a .gnode associated ProgramNode.
    func extractPersonEvent(from arg: ParsedExpr, tag: String, functionName: String) throws -> ProgramValue {
//        // Get the person with the requested event.
//        let person = try personFromProgramNode(arg, errorMessage: "\(functionName)() expects a person root node")
//        // Get the first child node with the even's tag in the person's tree.
//        return person.kid(withTag: tag).map { .gnode($0) } ?? .null

        return .null
    }
}
