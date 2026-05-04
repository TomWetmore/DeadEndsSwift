//
//  PersonSet.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 18 December 2024.
//  Last changed on 3 May 2026.
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

    let person: Person
    let key: String
    let payload: Payload?

    /// Create a person set element.
    public init(_ person: Person, payload: Payload? = nil) {

        guard person.tag == GedcomTag.INDI
        else { fatalError("person \(person.root) must be a keyed 0 INDI person") }
        self.person = person
        self.key = person.key
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

        let name = person.kid(withTag: "NAME")?.val ?? "<no name>"
        return "\(key): \(name)"
    }
    
    /// Compare two elements for name sorting.
    func nameSortsBefore(_ other: PersonSetElement) -> Bool {

        let lhsName = GedcomName(from: person.root)
        let rhsName = GedcomName(from: other.person.root)

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
    func append(_ person: Person, payload: Payload? = nil) {
        append(PersonSetElement(person, payload: payload))
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

    func clear() {
        elements.removeAll(keepingCapacity: true)
    }

    /// Sort a person set by name.
    func nameSort() {
        if sortType != .nameSorted {
            elements.sort { $0.nameSortsBefore($1) }
        }
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

    /// Create a person set from an array of person roots.
    public convenience init(persons: [Person]) {
        self.init()
        persons.forEach { self.elements.append(PersonSetElement<Payload>($0)) }
    }

    /// Create a person set form a single person root.
    public convenience init(person: Person) {
        self.init()
        self.elements.append(PersonSetElement<Payload>(person))
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
//    func keySort(unique: Bool = true) {
//        if sortType != .keySorted { keySort() }
//        if !self.unique && unique { removeDuplicates() }
//    }

    /// Sort a person set by key.
    func keySort() {
        if sortType != .keySorted {
            elements.sort { $0.key < $1.key }
        }
        sortType = .keySorted
    }
}
