//
//  PersonSet.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 18 December 2024.
//  Last changed on 27 March 2026.
//

import Foundation

/// A person set is in one of three sorted states.
enum SortType {
    case notSorted
    case keySorted
    case nameSorted
}

/// Element in a person set.
public struct PersonSetElement: Hashable, CustomStringConvertible {
    let root: Root  // Should be an INDI -- IS THIS CHECKED YET.
    let key: String

    /// Check if two sequence elements are equal.
    public static func == (lhs: PersonSetElement, rhs: PersonSetElement) -> Bool {
        return lhs.key == rhs.key
    }

    /// Hash a sequence element using its key.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }

    public var description: String {
        let name = root.kid(withTag: "NAME")?.val ?? "<no name>"
        return "\(key): \(name)"
    }
    
    /// Compare two elements for name sorting.
    func nameSortsBefore(_ other: PersonSetElement) -> Bool {
        let lhsName = GedcomName(from: root)
        let rhsName = GedcomName(from: other.root)

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

/// Sequence of person set elements. The underlying representation is an array
/// of sequence elements.
public class PersonSet: Collection {

    var elements: [PersonSetElement] = []
    var sortType: SortType = .notSorted
    // TODO: Change code so unique is no longer needed.
    var unique: Bool = true

    public var startIndex: Int { elements.startIndex }
    public var endIndex: Int { elements.endIndex }

    public func index(after i: Int) -> Int { elements.index(after: i) }

    public subscript(position: Int) -> PersonSetElement { elements[position] }

    public var count: Int { elements.count }
    public var isEmpty: Bool { elements.isEmpty }

    /// Append existing sequence element to sequence.
    func append(_ element: PersonSetElement) {
        elements.append(element)
    }

    /// Append new sequence element to sequence.
    func append(root: Root, key: String, name: String? = nil) {
        append(PersonSetElement(root: root, key: key))
    }

    /// Return deep copy of a record sequence.
    func copy() -> PersonSet {
        let copy = PersonSet()
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

/// Convenience initializers.
extension PersonSet {

    /// Create a person set from an array of Gedcom person roots.
    public convenience init(roots: [Root]) {
        self.init()
        for root in roots {
            let key = requireKey(on: root)
            self.elements.append(PersonSetElement(root: root, key: key))
        }
    }

    /// Create a person set from a single person root.
    public convenience init(root: Root) {
        self.init()
        let key = requireKey(on: root)
        self.elements.append(PersonSetElement(root: root, key: key))
    }
}

extension PersonSet: CustomStringConvertible {
    public var description: String {
        print("PersonSet(\(elements.count) elements)")
        for element in elements {
            print(element)
        }
        return ""
    }
}

extension PersonSet {

    /// Copy, key sort, and dedupe a record sequence.
//    private func normalizedCopy() -> PersonSet {
//        let copy = self.copy()
//        if copy.sortType != .keySorted { copy.keySort() }
//        if !copy.unique { copy.removeDuplicates() }
//        return copy
//    }

    /// Ensure that a sequence is key sorted and possibly deduped.
    func keySort(unique: Bool = true) {
        if sortType != .keySorted { keySort() }
        if !self.unique && unique { removeDuplicates() }
    }

//    func nremoveDuplicates() {
//        guard !elements.isEmpty else { return }
//
//        var uniqueElements: [PersonSetElement] = []
//        var previousKey: String? = nil
//
//        for element in elements {
//            if element.key != previousKey {
//                uniqueElements.append(element)
//                previousKey = element.key
//            }
//        }
//        elements = uniqueElements
//    }
}

/// Some proposed testing code.

/// Helper function to test PersonSets.
func makeSequence(keys: [String]) -> PersonSet {
    let sequence = PersonSet()
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
