//
//  PersonSetRelations.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 22 March 2026.
//  Last changed on 18 April 2026.
//

import Foundation

extension PersonSet {

    /// Return the children person set of a person set.
    public func childrenSet(in index: RecordIndex) -> PersonSet<Payload> {
        
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

    /// Return the parent person set of a person set.
    public func parentsSet(in index: RecordIndex) -> PersonSet<Payload> {

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

    /// Return the set of all spouses of persons in this set.
    /// The result may overlap with self.
    public func spouseSet(in index: RecordIndex) -> PersonSet<Payload> {

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

    /// Return the sibling person set of a person set.
    public func siblingSet(in index: RecordIndex) -> PersonSet<Payload> {

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

    /// Return the ancestors person set of a person set.
    public func ancestorSet(in index: RecordIndex) -> PersonSet<Payload> {

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

    /// Return the descendants person set of a person set.
    public func descendantSet(in index: RecordIndex) -> PersonSet<Payload> {

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

