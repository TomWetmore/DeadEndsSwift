//
//  PersonSetAlgebra.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 22 March 2026.
//  Last changed on 4 October 2026.
//

import Foundation

extension PersonSet {

    /// Return the union of two PersonSets.
    ///
    func union(_ other: PersonSet) -> PersonSet {

        let result = self.copy()
        for element in other.elements {
            result.insert(element)
        }
        return result
    }

    /// Insert the elements of another PersonSet into this PersonSet.
    ///
    func formUnion(_ other: PersonSet) {

        for element in other.elements {
            insert(element)
        }
    }

    /// Return the intersection of two PersonSets.
    ///
    func intersection(_ other: PersonSet) -> PersonSet {

        let result = PersonSet()

        for element in elements {
            if other.keys.contains(element.key) {
                result.insert(element)
            }
        }
        return result
    }

    /// Return the difference of two PersonSets.
    ///
    func difference(_ other: PersonSet) -> PersonSet {

        let result = PersonSet()

        for element in elements {
            if !other.keys.contains(element.key) {
                result.insert(element)
            }
        }
        return result
    }

    /// Determine if this PersonSet is a subset of another.
    ///
    func isSubset(of other: PersonSet) -> Bool {

        return keys.isSubset(of: other.keys)
    }

    /// Determine if this PersonSet is a superset of another.
    ///
    func isSuperset(of other: PersonSet) -> Bool {

        return other.isSubset(of: self)
    }
}
