//
//  TerminalInterface.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 20 July 2026.
//  Last changed on 24 July 2026.
//

import Foundation

public struct TerminalInterface: UserInterface {

    /// DEPRECATED. ngetPerson should replace this as the new getPerson
    public func getPerson(prompt: String?) async -> Person? {
        print("TerminalInterface.getPerson is deprecated")
        return nil
    }

    public init() {}

    /// Have the user enter an integer from the console.
    public func getInteger(prompt: String?) async -> Int? {

        while true {
            // Show the prompt, either provided or generic.
            if let prompt {
                writeStandardOutput(prompt + ": ")
            } else {
                writeStandardOutput("Enter an integer: ")
            }
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
            writeStandardOutput(prompt + ": ")
        } else {
            writeStandardOutput("Enter a string: ")
        }
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


private func writeStandardOutput(_ text: String) {
    FileHandle.standardOutput.write(Data(text.utf8))
}
