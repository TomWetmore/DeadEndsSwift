//
//  RecordSequence.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 18 December 2024.
//  Last changed on 20 March 2026.
//

import Foundation

/// A record squence is in one of three sorted states.
enum SortType {
    case notSorted
    case keySorted
    case nameSorted
}

/// Element in a person set.
struct PersonSetElement: Hashable {
    let node: Root
    let key: String

    /// Check if two sequence elements are equal.
    static func == (lhs: PersonSetElement, rhs: PersonSetElement) -> Bool {
        return lhs.key == rhs.key
    }

    /// Hash a sequence element using its key.
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }

    /// Compare two elements for name sorting.
    func nameSortsBefore(_ other: PersonSetElement) -> Bool {
        let lhsName = GedcomName(from: node)
        let rhsName = GedcomName(from: other.node)

        switch (lhsName, rhsName) {
        case let (lhs?, rhs?):
            if lhs < rhs { return true }
            if rhs < lhs { return false }
            return key < other.key
        case (_?, nil):
            return true      // named before unnamed
        case (nil, _?):
            return false     // unnamed after named
        case (nil, nil):
            return key < other.key
        }
    }
}

/// Sequence of record elements. The underlying representation is an array
/// of sequence elements.
final class RecordSequence: Collection {

    private var elements: [PersonSetElement] = []
    var sortType: SortType = .notSorted
    var unique: Bool = true

    var startIndex: Int { elements.startIndex }
    var endIndex: Int { elements.endIndex }

    func index(after i: Int) -> Int { elements.index(after: i) }

    subscript(position: Int) -> PersonSetElement { elements[position] }

    var count: Int { elements.count }
    var isEmpty: Bool { elements.isEmpty }

    /// Append existing sequence element to sequence.
    func append(_ element: PersonSetElement) {
        elements.append(element)
    }

    /// Append new sequence element to sequence.
    func append(root: Root, key: String, name: String? = nil) {
        append(PersonSetElement(node: root, key: key))
    }

    /// Return deep copy of a record sequence.
    func copy() -> RecordSequence {
        let copy = RecordSequence()
        copy.elements = self.elements
        copy.sortType = self.sortType
        copy.unique = self.unique
        return copy
    }

    /// Check if a sequence contains an element with a specific key.
    func isInSequence(key: RecordKey) -> Bool {
        switch sortType {
        case .keySorted:  // Binary search if sequence is key sorted.
            var low = 0
            var high = elements.count

            while low < high {
                let mid = (low + high) / 2
                let midKey = elements[mid].key

                if key == midKey {
                    return true
                } else if key < midKey {
                    high = mid
                } else {
                    low = mid + 1
                }
            }
            return false

        default:
            return elements.contains { $0.key == key }  // Otherwise linear search.
        }
    }

    /// Remove an element with a specific key from a sequence.
    func remove(key: String) -> Bool {
        if let index = elements.firstIndex(where: { $0.key == key }) {
            elements.remove(at: index)
            return true
        }
        return false
    }

    /// Sort a record sequence by key.
    func keySort() {
        elements.sort { $0.key < $1.key }
        sortType = .keySorted
    }

    /// Sort a record sequence by name.
    func nameSort() {
        elements.sort { $0.nameSortsBefore($1) }
        sortType = .nameSorted
    }

    /// Remove duplicates from a record sequence.
    func removeDuplicates() {
        var seenKeys = Set<String>()
        elements = elements.filter { element in
            if seenKeys.contains(element.key) {
                return false
            } else {
                seenKeys.insert(element.key)
                return true
            }
        }
        unique = true
    }
}

extension RecordSequence {

    /// Copy, key sort, and dedupe a record sequence.
    private func normalizedCopy() -> RecordSequence {
        let copy = self.copy()
        if copy.sortType != .keySorted { copy.keySort() }
        if !copy.unique { copy.removeDuplicates() }
        return copy
    }

    /// Union of two sequences, not affecting the sequences.
    func union(_ other: RecordSequence) -> RecordSequence {
        self.keySort()
        other.keySort()
        return self.sortedUnion(with: other)
    }

    /// Form union of two sequences in the first sequence.
    func formUnion(_ other: RecordSequence) {
        self.keySort()
        other.keySort()
        self.elements = self.sortedUnion(with: other).elements
        self.sortType = .keySorted
        self.unique = true
    }

    /// Ensure that a sequence is key sorted and possibly deduped.
    private func keySort(unique: Bool = true) {
        if sortType != .keySorted { keySort() }
        if !self.unique && unique { removeDuplicates() }
    }

    /// Intersection of two sequences, not affecting the two sequences.
    func intersection(_ other: RecordSequence) -> RecordSequence {
        self.keySort()
        other.keySort()
        return self.sortedIntersection(with: other)
    }

    func formIntersection(_ other: RecordSequence) {
        self.keySort()
        other.keySort()
        self.elements = self.sortedIntersection(with: other).elements
        self.sortType = .keySorted
        self.unique = true
    }

    /// Difference of two sequences, not affecting the two sequences.
    func difference(_ other: RecordSequence) -> RecordSequence {
        self.keySort()
        other.keySort()
        return self.sortedDifference(with: other)
    }

    func formDifference(_ other: RecordSequence) {
        self.keySort()
        other.keySort()
        self.elements = self.sortedDifference(with: other).elements
        self.sortType = .keySorted
        self.unique = true
    }

    /// Form union of key-sorted and deduped sequences. Operands not affected.
    private func sortedUnion(with other: RecordSequence) -> RecordSequence {
        let result = RecordSequence()
        var i = startIndex
        var j = other.startIndex

        while i < endIndex && j < other.endIndex {
            let elem1 = self[i]
            let elem2 = other[j]
            if elem1.key < elem2.key {
                result.append(elem1)
                i += 1
            } else if elem1.key > elem2.key {
                result.append(elem2)
                j += 1
            } else {
                result.append(elem1)
                i += 1
                j += 1
            }
        }
        while i < endIndex {
            result.append(self[i])
            i += 1
        }
        while j < other.endIndex {
            result.append(other[j])
            j += 1
        }
        result.sortType = .keySorted
        result.unique = true
        return result
    }

    /// Form intersection of key-sorted and deduped sequences. Operands not affected.
    private func sortedIntersection(with other: RecordSequence) -> RecordSequence {
        let result = RecordSequence()
        var i = startIndex
        var j = other.startIndex

        while i < endIndex && j < other.endIndex {
            let elem1 = self[i]
            let elem2 = other[j]
            if elem1.key < elem2.key {
                i += 1
            } else if elem1.key > elem2.key {
                j += 1
            } else {
                result.append(elem1)
                i += 1
                j += 1
            }
        }
        result.sortType = .keySorted
        result.unique = true
        return result
    }

    /// Form difference of key-sorted and deduped sequences. Operaands are not affected.
    private func sortedDifference(with other: RecordSequence) -> RecordSequence {
        let result = RecordSequence()
        var i = startIndex
        var j = other.startIndex

        while i < endIndex && j < other.endIndex {
            let elem1 = self[i]
            let elem2 = other[j]

            if elem1.key < elem2.key {
                result.append(elem1)
                i += 1
            } else if elem1.key > elem2.key {
                j += 1
            } else {
                i += 1
                j += 1
            }
        }
        while i < endIndex {
            result.append(self[i])
            i += 1
        }
        result.sortType = .keySorted
        result.unique = true
        return result
    }

    func nremoveDuplicates() {
        guard !elements.isEmpty else { return }

        var uniqueElements: [PersonSetElement] = []
        var previousKey: String? = nil

        for element in elements {
            if element.key != previousKey {
                uniqueElements.append(element)
                previousKey = element.key
            }
        }

        elements = uniqueElements
    }

    func isSubset(of other: RecordSequence) -> Bool {
        var i = startIndex
        var j = other.startIndex

        while i < endIndex && j < other.endIndex {
            let elem1 = self[i]
            let elem2 = other[j]

            if elem1.key < elem2.key {
                // Self has a key not found in other.
                return false
            } else if elem1.key > elem2.key {
                j += 1
            } else {
                // Keys match
                i += 1
                j += 1
            }
        }

        // If we didn't consume all of self, it isn't a subset.
        return i == endIndex
    }


    func isSuperset(of other: RecordSequence) -> Bool {
        return other.isSubset(of: self)
    }
}

// TEST CODE PROVIDED BY CHAT GPT

// Dummy helper function to create test RecordSequences easily
func makeSequence(keys: [String]) -> RecordSequence {
    let sequence = RecordSequence()
    for key in keys {
        let node = GedcomNode(key: key, tag: GedcomTag.INDI, val: nil) // dummy node
        sequence.append(root: node, key: key)
    }
    sequence.keySort()
    sequence.removeDuplicates()
    return sequence
}

// Run tests
func testRecordSequenceOperations() {
    print("Testing RecordSequence Set Operations...")

    let seqA = makeSequence(keys: ["@I1@", "@I2@", "@I3@", "@I5@"])
    let seqB = makeSequence(keys: ["@I2@", "@I4@", "@I5@", "@I6@"])

    // Test Union
    let unionSeq = seqA.union(seqB)
    assert(unionSeq.map { $0.key } == ["@I1@", "@I2@", "@I3@", "@I4@", "@I5@", "@I6@"],
           "Union failed")

    // Test Intersection
    let intersectionSeq = seqA.intersection(seqB)
    assert(intersectionSeq.map { $0.key } == ["@I2@", "@I5@"],
           "Intersection failed")

    // Test Difference (A - B)
    let differenceSeq = seqA.difference(seqB)
    assert(differenceSeq.map { $0.key } == ["@I1@", "@I3@"],
           "Difference failed")

    // Test Subset
    let subA = makeSequence(keys: ["@I2@", "@I5@"])
    assert(subA.isSubset(of: seqA), "Subset test failed")

    // Test Superset
    assert(seqA.isSuperset(of: subA), "Superset test failed")

    // Negative Subset Test
    let notSub = makeSequence(keys: ["@I2@", "@I7@"])
    assert(!notSub.isSubset(of: seqA), "Negative subset test failed")

    print("All RecordSequence Set Operation tests passed!")
}
