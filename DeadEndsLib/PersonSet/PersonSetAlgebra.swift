//
//  PersonSetAlgebra.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 22 March 2026.
//  Last changed on 22 March 2026.
//

import Foundation

/// Union operations.
extension PersonSet {

    /// Return union of two person sets.
    func union(_ other: PersonSet) -> PersonSet {
        self.keySort()
        other.keySort()
        return self.sortedUnion(with: other)
    }
    
    /// Form union of two person sets in the first person set.
    func formUnion(_ other: PersonSet) {
        self.keySort()
        other.keySort()
        self.elements = self.sortedUnion(with: other).elements
        self.sortType = .keySorted
        self.unique = true
    }

    /// Form union of key-sorted person sets.
    private func sortedUnion(with other: PersonSet) -> PersonSet {
        let result = PersonSet()
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
}

/// Intersection operations.
extension PersonSet {

    /// Intersection of two sequences, not affecting the two sequences.
    func intersection(_ other: PersonSet) -> PersonSet {
        self.keySort()
        other.keySort()
        return self.sortedIntersection(with: other)
    }

    func formIntersection(_ other: PersonSet) {
        self.keySort()
        other.keySort()
        self.elements = self.sortedIntersection(with: other).elements
        self.sortType = .keySorted
        self.unique = true
    }

    /// Form intersection of key-sorted and deduped sequences. Operands not affected.
    private func sortedIntersection(with other: PersonSet) -> PersonSet {
        let result = PersonSet()
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
}

/// Difference operations.
extension PersonSet {

    /// Find the difference between this person set and an other.
    func difference(_ other: PersonSet) -> PersonSet {
        self.keySort()
        other.keySort()
        return self.sortedDifference(with: other)
    }

    /// Find the difference between this person set and an other.
    func formDifference(_ other: PersonSet) {
        self.keySort()
        other.keySort()
        self.elements = self.sortedDifference(with: other).elements
        self.sortType = .keySorted
        self.unique = true
    }

    /// Form difference of key-sorted sets.
    private func sortedDifference(with other: PersonSet) -> PersonSet {
        let result = PersonSet()
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
}

/// Subset operations.
extension PersonSet {

    /// Determine if this person set is a subset of another.
    func isSubset(of other: PersonSet) -> Bool {
        var i = startIndex
        var j = other.startIndex

        while i < endIndex && j < other.endIndex {
            let elem1 = self[i]
            let elem2 = other[j]

            if elem1.key < elem2.key {  // Self has a key not in other.
                return false
            } else if elem1.key > elem2.key {
                j += 1
            } else {  // Keys match.
                i += 1
                j += 1
            }
        }
        return i == endIndex  // If didn't consume self, not a subset.
    }

    /// Determine if this person set is a superset of another.
    func isSuperset(of other: PersonSet) -> Bool {
        return other.isSubset(of: self)
    }
}
