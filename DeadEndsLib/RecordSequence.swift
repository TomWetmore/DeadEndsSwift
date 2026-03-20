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

/// Element in a record sequence.
struct SequenceElement: Hashable {
    let node: Root
    let key: String
    let name: String?

    /// Check if two sequence elements are equal.
    static func == (lhs: SequenceElement, rhs: SequenceElement) -> Bool {
        return lhs.key == rhs.key
    }

    /// Hash a sequence element. Key is enough.
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }

    /// Compare two elements for name sorting.
    func nameSortsBefore(_ other: SequenceElement) -> Bool {
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
/// of sequence elements. What does Collection get:
///   Element, Index, startIndex, endIndex, Iterator
final class RecordSequence: Collection {
    typealias Index = Int
    typealias Element = SequenceElement

    private var elements: [SequenceElement] = []
    var sortType: SortType = .notSorted
    var unique: Bool = true

    var startIndex: Int { elements.startIndex }
    var endIndex: Int { elements.endIndex }

    func index(after i: Int) -> Int { elements.index(after: i) }

    subscript(position: Int) -> SequenceElement { elements[position] }

    var count: Int { elements.count }
    var isEmpty: Bool { elements.isEmpty }

    /// Append existing sequence element to sequence.
    func append(_ element: SequenceElement) {
        elements.append(element)
    }

    /// Append new sequence element to sequence.
    func append(root: Root, key: String, name: String? = nil) {
        append(SequenceElement(node: root, key: key, name: name))
    }

    /// Return copy of a record sequence.
    /// This method creates a distinct new RecordSequence object whose content
    /// and state match the original. The elements array is copied by value,
    /// but because Swift arrays use copy-on-write, the old and new sequences will
    /// usually share underlying array storage until one of them is mutated.
    /// The metadata fields sortType and unique are copied as-is, under the
    /// assumption that they correctly describe the state of the original sequence.
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
    /// TODO: There is very likely a much better way to do this now. TODO.
    //    func nameSort() {
    //        elements.sort { ($0.name ?? "") < ($1.name ?? "") }
    //        sortType = .nameSorted
    //    }

    func sortByName() {
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

    /// Union of two sequences, not affecting the two sequences.
    func union(_ other: RecordSequence) -> RecordSequence {
        let left = self.normalizedCopy()
        let right = other.normalizedCopy()
        return left.sortedUnion(with: right)
    }

    /// Intersection of two sequences, not affecting the two sequences.
    func intersection(_ other: RecordSequence) -> RecordSequence {
        let left = self.normalizedCopy()
        let right = other.normalizedCopy()
        return left.sortedIntersection(with: right)
    }

    /// Difference of two sequences, not affecting the two sequences.
    func difference(_ other: RecordSequence) -> RecordSequence {
        let left = self.normalizedCopy()
        let right = other.normalizedCopy()
        return left.sortedDifference(with: right)
    }

    // MARK: - Sorted Core Algorithms

    private func sortedUnion(with other: RecordSequence) -> RecordSequence {
        let result = RecordSequence()
        var i = startIndex
        var j = other.startIndex

        while i < endIndex && j < other.endIndex {
            let elem1 = self[i]
            let elem2 = other[j]

            if elem1.key < elem2.key {
                result.append(elem1)
                i = index(after: i)
            } else if elem1.key > elem2.key {
                result.append(elem2)
                j = other.index(after: j)
            } else {
                result.append(elem1)
                i = index(after: i)
                j = other.index(after: j)
            }
        }

        while i < endIndex {
            result.append(self[i])
            i = index(after: i)
        }

        while j < other.endIndex {
            result.append(other[j])
            j = other.index(after: j)
        }

        result.sortType = .keySorted
        result.unique = true
        return result
    }

    private func sortedIntersection(with other: RecordSequence) -> RecordSequence {
        let result = RecordSequence()
        var i = startIndex
        var j = other.startIndex

        while i < endIndex && j < other.endIndex {
            let elem1 = self[i]
            let elem2 = other[j]

            if elem1.key < elem2.key {
                i = index(after: i)
            } else if elem1.key > elem2.key {
                j = other.index(after: j)
            } else {
                result.append(elem1)
                i = index(after: i)
                j = other.index(after: j)
            }
        }

        result.sortType = .keySorted
        result.unique = true
        return result
    }

    private func sortedDifference(with other: RecordSequence) -> RecordSequence {
        let result = RecordSequence()
        var i = startIndex
        var j = other.startIndex

        while i < endIndex && j < other.endIndex {
            let elem1 = self[i]
            let elem2 = other[j]

            if elem1.key < elem2.key {
                result.append(elem1)
                i = index(after: i)
            } else if elem1.key > elem2.key {
                j = other.index(after: j)
            } else {
                // Same key: skip
                i = index(after: i)
                j = other.index(after: j)
            }
        }

        while i < endIndex {
            result.append(self[i])
            i = index(after: i)
        }

        result.sortType = .keySorted
        result.unique = true
        return result
    }

    func nremoveDuplicates() {
        guard !elements.isEmpty else { return }

        var uniqueElements: [SequenceElement] = []
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
                j = other.index(after: j)
            } else {
                // Keys match
                i = index(after: i)
                j = other.index(after: j)
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
