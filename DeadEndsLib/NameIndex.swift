//
//  DeadEnds Librarty
//  NameIndex.swift
//
//  Created by Thomas Wetmore on 19 December 2024.
//  Last changed on 4 July 2025.
//

import Foundation

/// A `NameIndex` maps name keys to the sets of record keys of person with a name that matches the name key.
public struct NameIndex {

	static let map: [Character: String] = [ // Soundex based map used to generate name keys (not for phonetics).
		"B": "1", "F": "1", "P": "1", "V": "1",
		"C": "2", "G": "2", "J": "2", "K": "2", "Q": "2", "S": "2", "X": "2", "Z": "2",
		"D": "3", "T": "3",
		"L": "4",
		"M": "5", "N": "5",
		"R": "6"
	]

	// index is the underlying name index dictionary.
	// NOTE: MIGHT WANT TO MAKE INDEX PRIVATE AND ADD A PUBLIC ACCESSOR.
	var index = [String: Set<String>]()

	/// Adds an entry to the `NameIndex`; `name` is converted to its name key.
	public mutating func add(name: String, recordKey: String) {
		self.add(nameKey: nameKey(from: name), recordKey: recordKey)
	}

	/// Adds an entry to the `NameIndex`.
	mutating func add(nameKey: String, recordKey: String) {
		index[nameKey, default: Set()].insert(recordKey)
	}

    /// Removes an entry from the `NameIndex`; `name` is converted to its name key.
    public mutating func remove(name: String, recordKey: String) {
        remove(nameKey: nameKey(from: name), recordKey: recordKey)
    }

    /// Removes an entry from the `NameIndex` using a name key.
    mutating func remove(nameKey: String, recordKey: String) {
        if var records = index[nameKey] {
            records.remove(recordKey)
            // Remove record key set if now empty.
            if records.isEmpty {
                index.removeValue(forKey: nameKey)
            } else {
                index[nameKey] = records // Update the modified set
            }
        }
    }

	// Retrieve the record keys of a name key.
	func getKeys(forName name: String) -> Set<String>? {
		let nameKey = nameKey(from: name)
		return index[nameKey]
	}

	// printIndex is a debug method that prints a NameIndex.
	func printIndex() {
		for (nameKey, recordKeys) in index {
			print("Name Key: \(nameKey) => Records: \(Array(recordKeys))")
		}
	}
}

// getNameIndex creates and returns the name index of a list of persons.
func getNameIndex(persons: RootList) -> NameIndex {
	var nameIndex = NameIndex()
	for person in persons { // Loop all persons.
		let recordKey = person.key! // Must exist.
		person.traverseChildren { node in
			if node.tag == "NAME" { // Find all 1 NAME nodes
				if let name = node.value { // If nil earlier validation has added error to log.
					nameIndex.add(name: name, recordKey: recordKey)
				}
			}
		}
	}
	// print(nameIndex) // Debugging: Remove
	return nameIndex
}

// soundex finds the Soundex code of a string, generally a surname.
func soundex(for surname: String) -> String {
	var result = ""
	var previousCode: String? = nil

	for (i, char) in surname.uppercased().enumerated() {
		if i == 0 {
			result.append(char) // First letter kept.
		} else if let code = NameIndex.map[char], code != previousCode {
			result.append(code)
			previousCode = code
		}
	}
	while result.count < 4 { result.append("0") }
	if result.count > 4 { result = String(result.prefix(4)) }
	return result
}

// nameKey returns the name key of a string which is expected to have its surname separated by slashes.
func nameKey(from name: String) -> String {

	let n = name.compactMap { char in
		if char.isASCII && !char.isWhitespace { return char.uppercased() }
		return nil
	}.joined()

	enum State { case before, after, done }
	var state: State = .before
	var firstChar: Character = "$" // Default first letter
	var surname: String = ""

	for char in n {
		switch state {
		case .before:
			if char == "/" {
				state = .after
			} else if char.isLetter, firstChar == "$" {
				firstChar = char
			}
		case .after:
			if char == "/" {
				state = .done
			} else if char.isLetter {
				surname.append(char)
			}
		case .done:
			break
		}
	}
	return "\(firstChar)\(soundex(for: surname))"
}

/// Alias for a `GedcomNode` that is the root of a person record.
public typealias Person = GedcomNode

// Extension of GedcomNode where self is a Person root.
extension Person {

	/// Returns the array of non-nil values of the `1 NAME` lines in a person record.
    func names() -> [String] {
        return values(forTag: "NAME")
    }
}

// squeeze squeezes a string into an array of uppercase words.
func squeeze(_ input: String) -> [String] {
	input
		.split { !$0.isLetter }
		.map { String($0.uppercased()) }
}

// exactMatch checks that all words in the partial array are found in the full array and in the same order.
func exactMatch(partial: [String], complete: [String]) -> Bool {
	var partialIndex = 0
	var completeIndex = 0
	while partialIndex < partial.count && completeIndex < complete.count {
		if pieceMatch(partial[partialIndex], complete[completeIndex]) {
			partialIndex += 1
		}
		completeIndex += 1
	}
	return partialIndex == partial.count
}

// piecematch matches a partial word to a complete word. The first chars in each must be the same, and all chars
// in partial must be in complete and be in order.
func pieceMatch(_ partial: String, _ complete: String) -> Bool {
	guard let firstPartial = partial.first, let firstComplete = complete.first else { return false }
	guard firstPartial == firstComplete else { return false } // First chars must match.
	var partialIndex = partial.index(after: partial.startIndex)
	var completeIndex = complete.index(after: complete.startIndex)
	while partialIndex < partial.endIndex, completeIndex < complete.endIndex {
		if partial[partialIndex] == complete[completeIndex] {
			partialIndex = partial.index(after: partialIndex)
		}
		completeIndex = complete.index(after: completeIndex)
	}
	return partialIndex == partial.endIndex
}
