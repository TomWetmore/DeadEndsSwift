//
//  TerminalInterface.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 20 July 2026.
//  Last changed on 26 July 2026.
//

import Foundation

/// This is the Programming Language User Interface for use in CLI
/// programs that use the terminal for the interpreter input and
/// output channels. Standard error is used for output, and standard
/// input is used for input.
public struct TerminalInterface: UserInterface {

    /// The terminal interface output channel uses standard error.
    public func write(_ string: String) {
        FileHandle.standardError.write(Data(string.utf8))
    }

    /// The terminal interface input channel uses standard input.
    public func readString() -> String? {
        return readLine()
    }

    public init() {}

    /// Have the user enter an integer from the console.
    public func getInteger(prompt: String?) async -> Int? {

        while true {
            // Show the prompt, either provided or generic.
            if let prompt {
                write(prompt + ": ")
            } else {
                write("Enter an integer: ")
            }
            // User may want to bail.
            guard let line = readString() else { // EOF (Ctrl-D)
                writeLine()
                return nil
            }
            // Try to convert user's response to an integer.
            let text = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // An empty response also means no value.
            guard !text.isEmpty else {
                writeLine()
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
            write(prompt + ": ")
        } else {
            write("Enter a string: ")
        }
        // User may want to bail.
        guard let line = readString() else { // EOF (Ctrl-D)
            writeLine()
            return nil
        }
        // Trim white space.
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)

        // An empty response also means no value.
        guard !text.isEmpty else {
            writeLine()
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
            write(prompt)
        }
        writeLine()
        for (index, choice) in strings.enumerated() {
            writeLine("\(index + 1). \(choice)")
        }
        while true {
            guard let number = await getInteger(prompt: "Enter number") else {
                return nil
            }
            let index = number - 1
            if strings.indices.contains(index) {
                return index
            }
            writeLine("Enter a number from 1 through \(strings.count).")
        }
    }
}
