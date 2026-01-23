//
//  BuiltinPerson.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 12 April 2025.
//  Last changed on 12 January 2026.
//

import Foundation

extension Program {

    // builtinName returns the value of the first 1 NAME line in a person's record.
    func builtinName(_ arg: [ProgramNode]) throws -> ProgramValue {
        guard let person = try evaluatePerson(arg[0]) else {
            throw RuntimeError.typeError("name() expects a person parameter")
        }
        guard let name = person.kidVal(forTag: "NAME") else { return .null }
        return .string(name)
    }

    func builtinFullName(_ args: [ProgramNode]) throws -> ProgramValue {
        print("builtinFullName not implemented")
        return .null
    }

    // builtinSurname returns the surname found on the first NAME line in a person' record.
    func builtinSurname(_ arg: [ProgramNode]) throws -> ProgramValue {
        guard let person = try evaluatePerson(arg[0]) else {
            throw RuntimeError.typeError("surname() expects a person parameter")
        }
        guard let name = person.kidVal(forTag: "NAME") else { return .null }
        guard let gedcomName = GedcomName(string: name) else { return .null }
        guard let surname = gedcomName.surname else { return .null }
        return .string(surname)
    }

    // builtinGivens returns the given names ...
    func builtinGivens(_ arg: [ProgramNode]) throws -> ProgramValue {
        guard let person = try evaluatePerson(arg[0]) else {
            throw RuntimeError.typeError("givens() expects a person parameter")
        }
        guard let name = person.kidVal(forTag: "NAME") else { return .null }
        guard let gedcomName = GedcomName(string: name) else { return .null }
        return .string(gedcomName.nameParts.joined(separator: " "))
    }

    func builtinTrimName(_ args: [ProgramNode]) throws -> ProgramValue {
        // Get the person whose name is to be trimmed.
        let person = try personFromProgramNode(args[0], errorMessage: "trimName() expects a person argument");
        // Get the trim length.
        person.displayName(limit: 40) // figure out what it should be.
        print("builtinTrimName not implemented")
        return .null
    }

    // builtinBirth returns the first birth event for a person.
    func builtinBirth(_ arg: [ProgramNode]) throws -> ProgramValue {
        guard let person = try evaluatePerson(arg[0]) else {
            throw RuntimeError.typeError("birth() expects a person parameter")
        }
        guard let birth = person.kid(withTag: "BIRT") else { return .null }
        return .gnode(birth)
    }

    func builtinDeath(_ args: [ProgramNode]) throws -> ProgramValue {
        return try extractPersonEvent(from: args[0], tag: "DEAT", functionName: "death")
    }

    func builtinBurial(_ args: [ProgramNode]) throws -> ProgramValue {
        return try extractPersonEvent(from: args[0], tag: "BURI", functionName: "burial")
    }

    func builtinBaptism(_ args: [ProgramNode]) throws -> ProgramValue {
        return try extractPersonEvent(from: args[0], tag: "BAPM", functionName: "baptism")
    }

    // builtinFather is the builtin function that returns a person's father.
    func builtinFather(_ args: [ProgramNode]) throws -> ProgramValue {
        // Get the person whose father is to found.
        let person = try personFromProgramNode(args[0], errorMessage: "father() expects a person argument")
        // Get the person's father.
        if let father = person.father(in: self.recordIndex) {
            return .person(father)
        } else {
            return .null
        }
    }

    // builtinMother is the buitin function that returns a person's mother.
    func builtinMother(_ args: [ProgramNode]) throws -> ProgramValue {
        // Get the person whose mother is to be found.
        let person = try personFromProgramNode(args[0], errorMessage: "mother() expects a person argument")
        // Get the person's mother.
        if let mother = person.mother(in: self.recordIndex) {
            return .person(mother)
        } else {
            return .null
        }
    }

    // builtinNextSibling ...
    func builtinNextSibling(_ args: [ProgramNode]) throws -> ProgramValue {
        // Get the person whose next sibling is needed.
        let person = try personFromProgramNode(args[0], errorMessage: "nextsib() expects a person argument")
        // Get the next sibling of the person.
        if let nextSibling = person.nextSibling(in: self.recordIndex) {
            return .person(nextSibling)
        } else {
            return .null
        }
    }

    func builtinPrevSibling(_ args: [ProgramNode]) throws -> ProgramValue {
        // Get the person whose previous sibling is needed.
        let person = try personFromProgramNode(args[0], errorMessage: "prevsib() expects a person argument")
        // Get the previous sibling of the person.
        if let previousSibling = person.previousSibling(in: self.recordIndex) {
            return .person(previousSibling)
        } else {
            return .null
        }
    }

    func builtinSex(_ args: [ProgramNode]) throws -> ProgramValue {
        print("builtinSex not implemented")
        return .null
    }

    func builtinMale(_ args: [ProgramNode]) throws -> ProgramValue {
        // Get the person to be checked for being male.
        let person = try personFromProgramNode(args[0], errorMessage: "male() expects a person argument")
        return person.isMale ? ProgramValue.trueProgramValue : ProgramValue.falseProgramValue
    }

    func builtinFemale(_ args: [ProgramNode]) throws -> ProgramValue {
        // Get the person to be checked for being female.
        let person = try personFromProgramNode(args[0], errorMessage: "female() expects a person argument")
        return person.isFemale ? ProgramValue.trueProgramValue : ProgramValue.falseProgramValue
    }

    func builtinPronouns(_ args: [ProgramNode]) throws -> ProgramValue {
        print("builtInPronouns not implemented")
        return .null
    }

    func builtinNSpouses(_ args: [ProgramNode]) throws -> ProgramValue {
        print("builtinNSpouses not implemented")
        return .null
    }

    func builtinNFamilies(_ args: [ProgramNode]) throws -> ProgramValue {
        print("builtinNFamilies not implemented")
        return .null
    }

    func builtinParents(_ args: [ProgramNode]) throws -> ProgramValue {
        print("builtinParents not implemented")
        return .null
    }

    func builtinTitle(_ args: [ProgramNode]) throws -> ProgramValue {
        print("builtinTitle not implemented")
        return .null
    }

    // THIS ALSO WORKS FOR FAMIIES
    func builtinKey(_ args: [ProgramNode]) throws -> ProgramValue {
        print("builtinKey not implemented")
        return .null
    }

    func builtinSoundex(_ args: [ProgramNode]) throws -> ProgramValue {
        print("builtinSoundes not implemented")
        return .null
    }

    func builtinINode(_ args: [ProgramNode]) throws -> ProgramValue {
        print("builtinINode not implemented")
        return .null
    }

    func builtinRoot(_ args: [ProgramNode]) throws -> ProgramValue {
        print("builtinRoot not implemented")
        return .null
    }

    // builtinIndi looks up a person in the database and returns the person's root GedcomNode.
    func builtinIndi(_ args: [ProgramNode]) throws -> ProgramValue {
        // indi() requires a database.
        guard let database = self.database else { // TODO: Didn't we find a better way to do this? In Database.Swift?
            throw RuntimeError.missingDatabase("indi() requires a database")
        }
        // The argument to indi() must be a String.
        let val = try evaluate(args[0])
        guard case let .string(key) = val else {
            throw RuntimeError.typeError("indi() expects a string record key")
        }
        // Lookup the person in the database's record key.
        guard let node = database.recordIndex[normalizeRecordKey(key)] else {
            return .null
        }
        return .gnode(node)
    }

    func builtinFirstIndi(_ args: [ProgramNode]) throws -> ProgramValue {
        print("builtinFirstIndi not implemented")
        return .null
    }

    func builtinNextIndi(_ args: [ProgramNode]) throws -> ProgramValue {
        print("builtinNextIndi not implemented")
        return .null
    }

    func builtinPrevIndi(_ args: [ProgramNode]) throws -> ProgramValue {
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
    func builtinDate(_ arg: [ProgramNode]) throws -> ProgramValue {
        guard let event = try evaluateGedcomNode(arg[0]) else {
            throw RuntimeError.runtimeError("date() requires an event argument")
        }
        return ProgramValue.string(event.kidVal(forTag: "DATE") ?? "")
    }

    func builtinPlace(_ arg: [ProgramNode]) throws -> ProgramValue {
        guard let event = try evaluateGedcomNode(arg[0]) else {
            throw RuntimeError.runtimeError("place() requires an event argument")
        }
        return ProgramValue.string(event.kidVal(forTag: "PLAC") ?? "")
    }
}

extension Program {

    // Evaluate a ProgramNode that refers to a Person, and return that Person (its root GNode).
    func personFromProgramNode(_ pnode: ProgramNode, errorMessage: String) throws -> Person {
        // Evaluate the ProgramNode and find its line number in the original program.
        let pvalue = try evaluate(pnode)
        let line = pnode.line ?? 0
        // PValue must be a .gnode with a person root as associated value.
        guard case let .person(person) = pvalue, person.tag == "INDI" else {
            throw RuntimeError.typeError("\(line): \(errorMessage)")
        }
        return person
    }

    // Extract an event from a .gnode associated ProgramNode.
    func extractPersonEvent(from arg: ProgramNode, tag: String, functionName: String) throws -> ProgramValue {
        // Get the person with the requested event.
        let person = try personFromProgramNode(arg, errorMessage: "\(functionName)() expects a person root node")
        // Get the first child node with the even's tag in the person's tree.
        return person.kid(withTag: tag).map { .gnode($0) } ?? .null
    }
}
