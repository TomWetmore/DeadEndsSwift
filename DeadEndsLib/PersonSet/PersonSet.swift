//
//  PersonSet.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 18 December 2024.
//  Last changed on 17 April 2026.
//

import Foundation

public enum NoPayload {}
public typealias PlainPersonSet = PersonSet<NoPayload>

/// A person set can be in one of three sorted states.
enum SortType {

    case notSorted
    case keySorted
    case nameSorted
}

/// Element in a person set.
public struct PersonSetElement<Payload>: Hashable, CustomStringConvertible {

    let root: Root
    let key: String  // Not optional.
    let payload: Payload?

    /// Create an element; replaces the default init.
    public init(root: Root, payload: Payload? = nil) {

        guard root.tag == GedcomTag.INDI, let key = root.key
        else { fatalError("root \(root) must be a keyed 0 INDI node") }
        self.root = root
        self.key = key
        self.payload = payload
    }

    /// Check if two elements are equal.
    public static func == (lhs: PersonSetElement, rhs: PersonSetElement) -> Bool {
        return lhs.key == rhs.key
    }

    /// Hash an element using its key.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }

    /// Return the description of an element as a person's name.
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

/// Person set is a class that wraps an array of person set elements.
public class PersonSet<Payload>: Collection {

    var elements: [PersonSetElement<Payload>] = []
    var sortType: SortType = .notSorted
    // TODO: Change code so unique is no longer needed.
    var unique: Bool = true

    public var startIndex: Int { elements.startIndex }
    public var endIndex: Int { elements.endIndex }

    public func index(after i: Int) -> Int { elements.index(after: i) }

    public subscript(position: Int) -> PersonSetElement<Payload> { elements[position] }

    public var count: Int { elements.count }
    public var isEmpty: Bool { elements.isEmpty }

    /// Append an existing element to the set.
    func append(_ element: PersonSetElement<Payload>) {
        elements.append(element)
    }

    /// Append new a sequence element to the set.
    func append(_ root: Root, payload: Payload? = nil) {
        append(PersonSetElement(root: root, payload: payload))
    }

    /// Return deep copy of a set.
    func copy() -> PersonSet<Payload> {
        let copy = PersonSet<Payload>()
        copy.elements = self.elements
        copy.sortType = self.sortType
        copy.unique = self.unique
        return copy
    }

    /// Check if a set contains an element with a specific key.
    func isInSequence(key: RecordKey) -> Bool {

        switch sortType {
        case .keySorted:  // Binary search if set is key sorted.
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

    /// Remove an element with a specific key from a set.
    @discardableResult
    func remove(key: String) -> Bool {

        if let index = elements.firstIndex(where: { $0.key == key }) {
            elements.remove(at: index)
            return true
        }
        return false
    }

    /// Sort a person set by name.
    func nameSort() {
        elements.sort { $0.nameSortsBefore($1) }
        sortType = .nameSorted
    }

    /// Remove duplicates from a person set.
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
//    public convenience init(roots: [Root]) {
//        self.init()
//        roots.forEach { self.elements.append(PersonSetElement(root: $0)) }
//    }
//
//    /// Create a person set from a single person root.
//    public convenience init(root: Root) {
//        self.init()
//        self.elements.append(PersonSetElement(root: root))
//    }

    public convenience init(roots: [Root]) {
        self.init()
        roots.forEach { self.elements.append(PersonSetElement<Payload>(root: $0)) }
    }

    public convenience init(root: Root) {
        self.init()
        self.elements.append(PersonSetElement<Payload>(root: root))
    }
}

extension PersonSet: CustomStringConvertible {
    public var description: String {
        var buf = ""
        buf += "PersonSet(\(elements.count) elements)\n"
        elements.forEach { buf += "\($0)\n" }
        return buf
    }
}

extension PersonSet {

    /// Ensure that a person set is key sorted and possibly deduped.
    func keySort(unique: Bool = true) {
        if sortType != .keySorted { keySort() }
        if !self.unique && unique { removeDuplicates() }
    }
}

/// Proposed test code.

/// Helper function to test person sets.
func makeSequence(keys: [String]) -> PlainPersonSet {
    let sequence = PlainPersonSet()
    for key in keys {
        let node = GedcomNode(key: key, tag: GedcomTag.INDI, val: nil)
        sequence.append(node)
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
