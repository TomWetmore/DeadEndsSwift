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
        
        var seen = Set<RecordKey>()
        var children = [Person]()

        for element in elements {
            for child in element.person.children(in: index) {
                if seen.insert(child.key).inserted {
                    children.append(child)
                }
            }
        }
        return PersonSet(persons: children)
    }

    /// Return the parents PersonSet of a PersonSet.

    public func parents(in index: RecordIndex) -> PersonSet {

        var seen = Set<RecordKey>()
        var parents = [Person]()

        for element in elements {
            for parent in element.person.parents(in: index) {
                if seen.insert(parent.key).inserted {
                    parents.append(parent)

                }
            }
        }
        return PersonSet(persons: parents)
    }

    /// Return the spouses PersonSet of a PersonSet.

    public func spouses(in index: RecordIndex) -> PersonSet {

        var seen = Set<RecordKey>()
        var spouses = [Person]()

        for element in elements {
            for spouse in element.person.spouses(in: index) {
                if seen.insert(spouse.key).inserted {
                    spouses.append(spouse)
                }
            }
        }
        return PersonSet(persons: spouses)
    }

    /// Return the sibling PersonSet of a PersonSet.

    public func siblings(in index: RecordIndex) -> PersonSet {

        var seen = Set<RecordKey>()
        var siblings: [Person] = []

        for element in elements {
            for sibling in element.person.siblings(in: index) {
                if seen.insert(sibling.key).inserted {
                    siblings.append(sibling)
                }
            }
        }
        return PersonSet(persons: siblings)
    }

    /// Return the ancestors PersonSet of a PersonSet.

    public func ancestors(in index: RecordIndex) -> PersonSet {

        var seen: Set<RecordKey> = []
        var ancestors = [Person]()

        for element in elements {
            for ancestor in element.person.ancestors(in: index) {
                if seen.insert(ancestor.key).inserted {
                    ancestors.append(ancestor)
                }
            }
        }
        return PersonSet(persons: ancestors)
    }

    /// Return the descendants PersonSet of a PersonSet.

    public func descendants(in index: RecordIndex) -> PersonSet {

        var seen = Set<RecordKey>()
        var descendants = [Person]()

        for element in elements {
            for descendant in element.person.descendants(in: index) {
                if seen.insert(descendant.key).inserted {
                    descendants.append(descendant)
                }
            }
        }
        return PersonSet(persons: descendants)
    }
}

