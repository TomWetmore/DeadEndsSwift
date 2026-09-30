//
//  PersonSetRelations.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 22 March 2026.
//  Last changed on 21 September 2026.
//

import Foundation

extension PersonSet {

    /// Return the children PersonSet of a PersonSet.

    public func children(in index: RecordIndex) -> PersonSet {

        var children = [Person]()

        for element in elements {
            for child in element.person.children(in: index) {
                children.append(child)
            }
        }
        return PersonSet(persons: children)
    }

    /// Return the parents PersonSet of a PersonSet.

    public func parents(in index: RecordIndex) -> PersonSet {

        var parents = [Person]()

        for element in elements {
            for parent in element.person.parents(in: index) {
                parents.append(parent)
            }
        }
        return PersonSet(persons: parents)
    }

    /// Return the spouses PersonSet of a PersonSet.

    public func spouses(in index: RecordIndex) -> PersonSet {

        var spouses = [Person]()

        for element in elements {
            for spouse in element.person.spouses(in: index) {
                spouses.append(spouse)
            }
        }
        return PersonSet(persons: spouses)
    }

    /// Return the sibling PersonSet of a PersonSet.

    public func siblings(in index: RecordIndex) -> PersonSet {

        var siblings: [Person] = []

        for element in elements {
            for sibling in element.person.siblings(in: index) {
                siblings.append(sibling)
            }
        }
        return PersonSet(persons: siblings)
    }

    /// Return the ancestors PersonSet of a PersonSet.

    public func ancestors(in index: RecordIndex) -> PersonSet {

        var ancestors = [Person]()

        for element in elements {
            for ancestor in element.person.ancestors(in: index) {
                ancestors.append(ancestor)
            }
        }
        return PersonSet(persons: ancestors)
    }

    /// Return the descendants PersonSet of a PersonSet.

    public func descendants(in index: RecordIndex) -> PersonSet {

        var descendants = [Person]()

        for element in elements {
            for descendant in element.person.descendants(in: index) {
                descendants.append(descendant)
            }
        }
        return PersonSet(persons: descendants)
    }
}
