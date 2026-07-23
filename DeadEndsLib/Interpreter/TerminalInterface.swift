//
//  TerminalInterface.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 20 July 2026.
//  Last changed on 23 July 2026.
//

import Foundation

public struct TerminalInterface: UserInterface {

    /// DEPRECATED. ngetPewrson should replace this as the new getPerson
    public func getPerson(prompt: String?) async -> Person? {
        return nil
    }

    public init() {}

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
            // Successful return.
            if let value = Int(text) { return value }
        }
    }

    /// Have the user enter a string from the console.
    public func getString(prompt: String?) async -> String? {

        // Show the prompt, either provided or generic.
        if let prompt {
            print(prompt, terminator: ": ")
        } else {
            print("Enter a string: ")
        }
        fflush(stdout)
        // User may want to bail.
        guard let line = readLine() else { // EOF (Ctrl-D)
            print()
            return nil
        }
        // Trim white space.
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)

        // An empty response also means no value.
        guard !text.isEmpty else {
            print()
            return nil
        }
        // Successful return.
        return text
    }
}

extension TerminalInterface {

    /// Choose from a list of Strings.
    public func chooseFromList(prompt: String?, strings: [String]) async -> Int? {

        guard !strings.isEmpty else {
            return nil
        }
        if let prompt {
            print(prompt)
        }
        for (index, choice) in strings.enumerated() {
            print("\(index + 1). \(choice)")
        }
        while true {
            guard let number = await getInteger(prompt: "Enter number") else {
                return nil
            }
            let index = number - 1
            if strings.indices.contains(index) {
                return index
            }
            print("Enter a number from 1 through \(strings.count).")
        }
    }
}

extension TerminalInterface {

//    public func choosePerson(prompt: String?, persons: [Person]) async -> Person? {
//
//        guard !persons.isEmpty else {
//            return nil
//        }
//
//        if let prompt {
//            print(prompt)
//        }
//
//        for (index, person) in persons.enumerated() {
//            print("\(index + 1). \(personSummary(person))")
//        }
//
//        while true {
//            guard let choice = await getInteger(prompt: "Enter number") else {
//                return nil
//            }
//
//            let index = choice - 1
//
//            guard persons.indices.contains(index) else {
//                print("Enter a number from 1 through \(persons.count).")
//                continue
//            }
//
//            return persons[index]
//        }
//    }
}

/// Eventually to replace the bltinGetPerson now used by the SwiftUI interface.
/// What this method should do:
/// 1.
extension Program {
    
    
}


//    public func getPerson(prompt: String?) async -> Person? {
//        while true {
//            let searchText = await getString(
//                prompt: prompt ?? "Enter a person's name"
//            )
//
//            guard let searchText else {
//                return nil
//            }
//
//            let matches = database.persons(matching: searchText)
//                .sorted(by: personLexicographicOrder)
//
//            guard !matches.isEmpty else {
//                print("No matching persons.")
//                continue
//            }
//
//            if matches.count == 1 {
//                print(personSummary(matches[0]))
//                return matches[0]
//            }
//
//            for (index, person) in matches.enumerated() {
//                print("\(index + 1). \(personSummary(person))")
//            }
//
//            while true {
//                guard let choice = await getInteger(prompt: "Enter number") else {
//                    return nil
//                }
//
//                guard matches.indices.contains(choice - 1) else {
//                    print("Please enter a number from 1 through \(matches.count).")
//                    continue
//                }
//
//                return matches[choice - 1]
//            }
//        }
//    }
