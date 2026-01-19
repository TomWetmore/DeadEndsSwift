//
//  DeadEnds Librarty
//  NameIndex.swift
//
//  Created by Thomas Wetmore on 19 December 2024.
//  Last changed on 3 January 2026.
//

import Foundation

/// A NameIndex maps NameKeys to Sets of RecordKeys of persons with names that match the NameKey.

final public class NameIndex {

	static let map: [Character: String] = [ // Soundex based map used to generate name keys.
		"B": "1", "F": "1", "P": "1", "V": "1",
		"C": "2", "G": "2", "J": "2", "K": "2", "Q": "2", "S": "2", "X": "2", "Z": "2",
		"D": "3", "T": "3",
		"L": "4",
		"M": "5", "N": "5",
		"R": "6"
	]

	/// Underlying name index dictionary.
	var index = [NameKey: Set<RecordKey>]()

	/// Adds an entry to the NameIndex; value is a 1 NAME value and is converted to a NameKey.
	public func add(value: String, recordKey: RecordKey) {
        guard let gedcomName = GedcomName(string: value) else { return }
		self.add(nameKey: gedcomName.nameKey, recordKey: recordKey)
	}

	/// Adds an entry to the NameIndex.
	func add(nameKey: String, recordKey: String) {
		index[nameKey, default: Set()].insert(recordKey)
	}

    /// Removes an entry from the NameIndex; value is a 1 NAME value that is converted to a NameKey.
    public func remove(value: String, recordKey: RecordKey) {
		
        guard let gedcomName = GedcomName(string: value) else { return }
        remove(nameKey: gedcomName.nameKey, recordKey: recordKey)
    }

    /// Removes an entry from the NameIndex.
    func remove(nameKey: NameKey, recordKey: RecordKey) {
		
        if var records = index[nameKey] {
            records.remove(recordKey)
            if records.isEmpty { index.removeValue(forKey: nameKey) }
            else { index[nameKey] = records } // Update the record set.
        }
    }

	/// Gets the record keys that match a Gedcom name or pattern. The value is converted to a NameKey
    /// and then looked up in the NameIndex.
	func keys(forName value: String) -> Set<RecordKey>? {
		return index[nameKey(value: value)]
	}

	/// Debug method that shows the contents of the NameIndex.
	func showContents() {
		for (nameKey, recordKeys) in index {
			print("Name Key: \(nameKey) => Records: \(Array(recordKeys))")
		}
	}
}

/// Returns the name key of a 1 NAME value.
func nameKey(value: String) -> String {
    guard let gedcomName = GedcomName(string: value) else {
        fatalError("Invalid name: \(value)")
    }
    return gedcomName.nameKey
}

/// This simple looking function builds the NameIndex for a Database.
func buildNameIndex(from persons: RecordList) -> NameIndex {
    let index = NameIndex()
    for person in persons {
        guard let recordKey = person.key else { continue }  // Will succeed.
        let nameNodes = person.kids(withTag: "NAME")
        for node in nameNodes {
            guard let name = node.val, !name.isEmpty, let gedcomName = GedcomName(string: name)
            else { continue }  // Will succeed.
            index.add(nameKey: gedcomName.nameKey, recordKey: recordKey)
        }
    }
    return index
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

// Extension of GedcomNode where self is a Person root.
extension Person {

	/// Returns the array of non-nil values of the 1 NAME lines in a Person.
    var nameValues: [String] {
        self.root.kidVals(forTag: "NAME")
    }
}

// squeeze squeezes a string into an array of uppercase words.
func squeeze(_ input: String) -> [String] {
	input
		.split { !$0.isLetter }
		.map { String($0.uppercased()) }
}

// Checks that all words in the partial array are found in the full array and in the same order.
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

extension Database {

    /// Returns the Array of RecordKeys of all Persons with names that match a pattern.
    public func personKeys(forName pattern: String) -> [RecordKey] {
        var matchingKeys: [String] = []
        let nameKey = nameKey(value: pattern) // Name key of name pattern.
        guard let recordKeys = nameIndex.index[nameKey] else { return [] }  // Persons keys that match nameKey.
        let squeezedPattern: [String] = squeeze(pattern) // Prepare pattern for matching.
        // Filter candidates based on exactMatch logic.
        for recordKey in recordKeys {
            if let person = recordIndex.person(for: recordKey) {
                for nameValue in person.nameValues {
                    let squeezedPersonName = squeeze(nameValue)
                    if exactMatch(partial: squeezedPattern, complete: squeezedPersonName) {
                        matchingKeys.append(recordKey)
                        break // No need to check other names of this Person.
                    }
                }
            }
        }
        return matchingKeys
    }

    /// Returns the Array of all Persons with names that match a name pattern.
    public func persons(withName pattern: String) -> [Person] {
        personKeys(forName: pattern).compactMap { recordIndex.person(for: $0) }
    }
}
