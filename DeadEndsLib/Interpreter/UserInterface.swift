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
    func ngetPerson(prompt: String?, database: Database) async -> Person? {

        // Ask the user for a name pattern.
        guard let pattern = await self.getString(prompt: prompt) else {
            return nil
        }
        // Get the persons who match the name.
        let persons = database.persons(withName: pattern)
        if persons.isEmpty { return nil }

        /*
         2. Use that name pattern to get a list of sorted names with basic vital info.
         3. Use chooseFromList to have the user choose the line with the name.
         4. Get the Person from that choice and return it.
         */
        print("hello, world\n")
        return nil
    }
}


