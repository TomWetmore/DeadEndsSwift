//
//  PersonSetAlgebra.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 22 March 2026.
//  Last changed on 21 September 2026.
//

import Foundation

extension PersonSet {

    /// Return the union of two PersonSets with duplicate keys removed.

    func union(_ other: PersonSet) -> PersonSet {

        let result = PersonSet()
        var seen = Set<RecordKey>()

        for element in elements {
            if seen.insert(element.key).inserted {
                result.append(element)
            }
        }
        for element in other.elements {
            if seen.insert(element.key).inserted {
                result.append(element)
            }
        }
        return result
    }

    /// Return intersection of two PersonSets with duplicte keys removed.

    func intersection(_ other: PersonSet) -> PersonSet {

        let result = PersonSet()
        let otherKeys = Set(other.elements.map(\.key))
        var seen = Set<RecordKey>()

        for element in elements {
            if otherKeys.contains(element.key),
               seen.insert(element.key).inserted {
                result.append(element)
            }
        }
        return result
    }

    /// Return difference of two PersonSets with duplicate keys removed.

    func difference(_ other: PersonSet) -> PersonSet {

        let result = PersonSet()
        let otherKeys = Set(other.elements.map(\.key))
        var seen = Set<RecordKey>()

        for element in elements {
            if !otherKeys.contains(element.key),
               seen.insert(element.key).inserted {
                result.append(element)
            }
        }
        return result
    }

    /// Determine if this PersonSet is a subset of another.

    func isSubset(of other: PersonSet) -> Bool {

        let otherKeys = Set(other.elements.map(\.key))

        for element in elements {
            if !otherKeys.contains(element.key) {
                return false
            }
        }
        return true
    }

    /// Determine if this PersonSet is a superset of another.

    func isSuperset(of other: PersonSet) -> Bool {

        return other.isSubset(of: self)
    }
}
