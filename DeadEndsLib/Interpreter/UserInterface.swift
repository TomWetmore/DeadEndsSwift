//
//  UserInterface.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 19 May 2026.
//  Last changed on 21 July 2026.
//

import Foundation

/// The DeadEnds programming language has built-in functions that interact with users.
/// The details of specific user interface types are hidden from the built-in by their
/// use of methods defined by this UserInterface protocol.

@MainActor
public protocol UserInterface {

    //func getPerson(prompt: String?) async -> Person?
//    func getPersonSet(prompt: String?) async -> PersonSet<ProgramValue>?
//    func getFamily(prompt: String?) async -> Family?
    func getInteger(prompt: String?) async -> Int?
    func getString(prompt: String?) async -> String?
    func getPerson(prompt: String?) async -> Person?  // DEPRECATED

    //func choosePerson(prompt: String?, persons: [Person]) async -> Person?
    //func chooseString(prompt: String?, strings: [String]) async -> String?
    func chooseFromList(prompt: String?, strings: [String]) async -> Int?


//    func chooseChild(from value: ProgramValue) async -> Person?
//    func chooseFamily(of person: Person) async -> Family?
//    func chooseSpouse(of person: Person) async -> Person?
//    func chooseSubset(from set: PersonSet<ProgramValue>) async -> PersonSet<ProgramValue>?

    // Generic menu
//    func menuChoose(from list: List, prompt: String?) async -> Int?
}

extension UserInterface {

    /// Implemented operation protocol method that uses primitive (per interface) methods
    /// to get a person from the user.
    /// Shared person-selection operation implemented in terms of
    /// interface-specific primitives.
    func ngetPerson(prompt: String?, database: Database) async -> Person? {

        // Ask user for a name pattern using the getString primitive.
        guard let pattern = await getString(prompt: prompt) else {
            return nil
        }
        // Get the persons who match the name.
        let persons = database.persons(withName: pattern)
        if persons.isEmpty { return nil }

        // Get the array of person choice strings to show the user.
        let choices = persons.map { person in person.displayLine }

        // Get the user's choice using the chooseFromList primitive.
        guard let choice = await chooseFromList(
            prompt: "Enter the person's index: ", strings: choices) else {
            return nil
        }

        guard persons.indices.contains(choice) else {
            return nil
        }

        return persons[choice]
    }
}

