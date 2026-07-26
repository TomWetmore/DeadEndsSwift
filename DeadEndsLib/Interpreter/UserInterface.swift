//
//  UserInterface.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 19 May 2026.
//  Last changed on 25 July 2026.
//

import Foundation

/// The DeadEnds programming language has built-in functions that interact with users.
/// The details of specific user interface types are hidden from the built-in by their
/// use of methods defined by this UserInterface protocol.

@MainActor
/// UserInterface primitives.
public protocol UserInterface {

    func getInteger(prompt: String?) async -> Int?
    func getString(prompt: String?) async -> String?
    func getPerson(prompt: String?, database: Database) async -> Person?

    func chooseFromList(prompt: String?, strings: [String]) async -> Int?

    func write(_ string: String)
    func readString() -> String?
}

/// Implemented operations.
extension UserInterface {

    /// Get a person. TODO: This will morph into the final getPerson method.
    public func getPerson(prompt: String?, database: Database) async -> Person? {

        // Ask the user for a name pattern.
        guard let pattern = await getString(prompt: prompt) else {
            return nil
        }
        // Find the persons who match the pattern.
        let persons = database.persons(withName: pattern)
        if persons.isEmpty { return nil }

        // Get the array of person choice strings to show the user.
        let choices = persons.map { person in person.displayLine }

        // Get the user's choice.
        guard let choice = await chooseFromList(
            prompt: "Enter the person's index: ", strings: choices)
        else {
            return nil
        }
        // Validate the index.
        guard persons.indices.contains(choice) else { return nil }
        // Return user's choice.
        return persons[choice]
    }

    func writeLine(_ string: String = "") {
        write(string + "\n")
    }
}
