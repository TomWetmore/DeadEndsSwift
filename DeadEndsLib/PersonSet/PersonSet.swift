//
//  PersonSet.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 18 December 2024.
//  Last changed on 29 September 2026.
//
//  PersonSets are the objects used by the programming system to hold
//  rich collections of persons.
//  PersonSets are not used within the main (non-programming) part of DeadEnds.
//

import Foundation

/// A PersonSet can be in one of three sorted states.

enum SortType {

    case notSorted
    case keySorted
    case nameSorted

}

/// Element of a PersonSet. It contains a Person, the Person's key, and an optional
/// ProgramValue.

public struct PersonSetElement: Hashable, CustomStringConvertible {

    let person: Person

    let key: String

    let value: ProgramValue?

    var name: String {
        person.name
    }

    /// Create a PersonSetElement.

    public init(_ person: Person, value: ProgramValue? = nil) {

        guard person.tag == GedcomTag.INDI
        else { fatalError("person \(person.root) must be a keyed 0 INDI person") }
        self.person = person
        self.key = person.key
        self.value = value
    }

    /// Check if two PersonSetElements are equal.

    public static func == (lhs: PersonSetElement, rhs: PersonSetElement) -> Bool {

        return lhs.key == rhs.key
    }

    /// Hash a PersonSetElement using its key.

    public func hash(into hasher: inout Hasher) {

        hasher.combine(key)
    }

    /// Return the description of a PersonSetElement as the Person's name.
    ///
    public var description: String {

        return "\(key): \(name)"
    }
    
    /// Compare two PersonSetElements for name sorting.

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

/// PersonSet is a class that wraps an array of PersonSetElements.

public class PersonSet: Collection {

    var elements: [PersonSetElement] = []

    var keys: Set<RecordKey> = []

    var sortType: SortType = .notSorted

    public var startIndex: Int { elements.startIndex }
    
    public var endIndex: Int { elements.endIndex }

    public func index(after i: Int) -> Int { elements.index(after: i) }

    public subscript(position: Int) -> PersonSetElement { elements[position] }

    public var count: Int { elements.count }
    
    public var isEmpty: Bool { elements.isEmpty }

    /// Insert a PersonSetElement into a PersonSet. Not added if the RecordKey is already
    /// used.

    @discardableResult
    func insert(_ element: PersonSetElement) -> Bool {

        if keys.insert(element.key).inserted {
            elements.append(element)
            sortType = .notSorted
            return true
        }
        return false
    }

    /// Create and insert a new PersonSetElement in a PersonSet. Not added if the Person's
    /// RecordKey is already used.

    @discardableResult
    func insert(_ person: Person, value: ProgramValue? = nil) -> Bool {

        insert(PersonSetElement(person, value: value))
    }

    /// Return a deep copy of a PersonSet.

    func copy() -> PersonSet {
        
        let copy = PersonSet()
        copy.elements = self.elements
        copy.keys = keys
        copy.sortType = self.sortType
        return copy
    }

    /// Check if a PersonSet contains a PersonSetElement with a specific key.

    func isInPersonSet(key: RecordKey) -> Bool {

        keys.contains(key)
    }

    /// Remove all PersonSetElements with a specific key from a PersonSet. There can be only
    /// one.

    @discardableResult
    func remove(key: RecordKey) -> Bool {

        guard keys.remove(key) != nil else {
            return false
        }
        elements.removeAll { $0.key == key }
        return true
    }

    /// Remove all PersonSetElements from a PersonSet.

    func clear() {

        elements.removeAll(keepingCapacity: true)
        keys.removeAll(keepingCapacity: true)
    }

    /// Sort a PersonSet by name.

    func nameSort() {

        if sortType != .nameSorted {
            elements.sort { $0.nameSortsBefore($1) }
        }
        sortType = .nameSorted
    }
}

/// Convenience initializers.

extension PersonSet {

    /// Create a PersonSet from an array of Persons.

    public convenience init(persons: [Person]) {

        self.init()
        persons.forEach { insert($0) }
    }

    /// Create a PersonSet from a Person.

    public convenience init(person: Person) {

        self.init()
        insert(person)
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

    /// Sort a PersonSet by key.

    func keySort() {

        if sortType != .keySorted {
            elements.sort { $0.key < $1.key }
        }
        sortType = .keySorted
    }
}
