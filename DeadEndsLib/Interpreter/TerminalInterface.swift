//
//  TerminalInterface.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 20 July 2026.
//  Last changed on 20 July 2026.
//

import Foundation

public struct TerminalInterface: UserInterface {

    public init() {}

    public func getPerson(prompt: String?) async -> Person? {
        while true {
            let searchText = await getString(
                prompt: prompt ?? "Enter a person's name"
            )

            guard let searchText else {
                return nil
            }

            let matches = database.persons(matching: searchText)
                .sorted(by: personLexicographicOrder)

            guard !matches.isEmpty else {
                print("No matching persons.")
                continue
            }

            if matches.count == 1 {
                print(personSummary(matches[0]))
                return matches[0]
            }

            for (index, person) in matches.enumerated() {
                print("\(index + 1). \(personSummary(person))")
            }

            while true {
                guard let choice = await getInteger(prompt: "Enter number") else {
                    return nil
                }

                guard matches.indices.contains(choice - 1) else {
                    print("Please enter a number from 1 through \(matches.count).")
                    continue
                }

                return matches[choice - 1]
            }
        }
    }

    /// Have the user enter an integer from the console.
    public func getInteger(prompt: String?) async -> Int? {

        while true {
            // Show the prompt, either provided or generic.
            if let prompt {
                print(prompt, terminator: ": ")
            } else {
                print("Enter an integer: ")
            }
            fflush(stdout)

            // User may want to bail.
            guard let line = readLine() else { // EOF (Ctrl-D)
                print()
                return nil
            }
            // Try to convert user's response to an integer.
            let text = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // An empty response also means no value.
            guard !text.isEmpty else {
                print()
                return nil
            }

            if let value = Int(text) { return value }
        }
    }

    public func getString(prompt: String?) async -> String? {
        return nil
    }
}



