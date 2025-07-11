//
//  RecordSequence.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 18 December 2024.
//  Last changed on 26 April 2025.
//

import Foundation

// SortType specifies how a sequence is sorted.
enum SortType {
	case notSorted
	case keySorted
	case nameSorted
}

// SequenceElement is an element in a RecordSequence.
struct SequenceElement: Hashable {
	let node: GedcomNode
	let key: String
	let name: String?

    // == checks if two SequenceElements are equal.
	static func == (lhs: SequenceElement, rhs: SequenceElement) -> Bool {
		return lhs.key == rhs.key && lhs.name == rhs.name
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(key)
		hasher.combine(name)
	}
}

class RecordSequence: Collection {
    typealias Index = Int
    typealias Element = SequenceElement

    private var elements: [SequenceElement] = []
    var sortType: SortType = .notSorted
    var unique: Bool = false

    // MARK: - Collection requirements
    var startIndex: Int { elements.startIndex }
    var endIndex: Int { elements.endIndex }

    func index(after i: Int) -> Int {
        elements.index(after: i)
    }

    subscript(position: Int) -> SequenceElement {
        elements[position]
    }

    // MARK: - Custom methods
    func append(_ element: SequenceElement) {
        elements.append(element)
    }

    func append(root: GedcomNode, key: String, name: String? = nil) {
        let element = SequenceElement(node: root, key: key, name: name)
        append(element)
    }

    func copy() -> RecordSequence {
        let copy = RecordSequence()
        copy.elements = self.elements
        copy.sortType = self.sortType
        copy.unique = self.unique
        return copy
    }

    func isInSequence(key: String) -> Bool {
        elements.contains { $0.key == key }
    }

    func remove(key: String) -> Bool {
        if let index = elements.firstIndex(where: { $0.key == key }) {
            elements.remove(at: index)
            return true
        }
        return false
    }

    func keySort() {
        elements.sort { $0.key < $1.key }
        sortType = .keySorted
    }

    func nameSort() {
        elements.sort { ($0.name ?? "") < ($1.name ?? "") }
        sortType = .nameSorted
    }

    func union(_ other: RecordSequence) -> RecordSequence {
        let combined = RecordSequence()
        combined.elements = Array(Set(self.elements + other.elements))
        return combined
    }

    func intersection(_ other: RecordSequence) -> RecordSequence {
        let otherKeys = Set(other.elements.map { $0.key })
        let result = RecordSequence()
        result.elements = elements.filter { otherKeys.contains($0.key) }
        return result
    }

    func difference(_ other: RecordSequence) -> RecordSequence {
        let otherKeys = Set(other.elements.map { $0.key })
        let result = RecordSequence()
        result.elements = elements.filter { !otherKeys.contains($0.key) }
        return result
    }

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
    }
}

extension RecordSequence {

    // MARK: - Normalization Helpers

    private func normalizedCopy() -> RecordSequence {
        let copy = self.copy()
        if copy.sortType != .keySorted {
            copy.keySort()
        }
        if !copy.unique {
            copy.removeDuplicates()
            copy.unique = true
        }
        return copy
    }

    // MARK: - Set Operations

    func nunion(_ other: RecordSequence) -> RecordSequence {
        let left = self.normalizedCopy()
        let right = other.normalizedCopy()
        return left.sortedUnion(with: right)
    }

    func nintersection(_ other: RecordSequence) -> RecordSequence {
        let left = self.normalizedCopy()
        let right = other.normalizedCopy()
        return left.sortedIntersection(with: right)
    }

    func ndifference(_ other: RecordSequence) -> RecordSequence {
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
        let node = GedcomNode(key: key, tag: "INDI", value: nil) // dummy node
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
