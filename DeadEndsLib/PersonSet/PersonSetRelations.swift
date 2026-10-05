//
//  PersonSetRelations.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 22 March 2026.
//  Last changed on 4 October 2026.
//

import Foundation

extension PersonSet {

    /// Return the children PersonSet of a PersonSet.
    ///
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
    ///
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
    ///
    public func spouses(in index: RecordIndex) -> PersonSet {

        var spouses = [Person]()

        for element in elements {
            for spouse in element.person.spouses(in: index) {
                spouses.append(spouse)
            }
        }
        return PersonSet(persons: spouses)
    }

    /// Return the siblings PersonSet of a PersonSet.
    ///
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
    ///
    public func ancestors(in index: RecordIndex) -> PersonSet {

        let result = PersonSet()

        for element in elements {
            for ancestor in element.person.ancestors(in: index) {
                result.insert(ancestor)
            }
        }

        return result
    }

    /// Return the descendants PersonSet of a PersonSet.
    ///
    public func descendants(in index: RecordIndex) -> PersonSet {

        let result = PersonSet()

        for element in elements {
            for descendant in element.person.descendants(in: index) {
                result.insert(descendant)
            }
        }
        return result
    }

    /// Return the fathers PersonSet of a PersonSet.
    ///
    public func fathers(in index: RecordIndex) -> PersonSet {

        let result = PersonSet()

        for element in elements {

            for father in element.person.fathers(in: index) {
                result.insert(father)
            }
        }
        return result
    }

    /// Return the mothers PersonSet of a PersonSet.
    ///
    public func mothers(in index: RecordIndex) -> PersonSet {

        let result = PersonSet()

        for element in elements {

            for mother in element.person.mothers(in: index) {
                result.insert(mother)
            }
        }
        return result
    }
}

/// Sons, daughters, brothers, sisters

extension PersonSet {

    /// Return the sons PersonSet of a PersonSet.
    ///
    public func sons(in index: RecordIndex) -> PersonSet {

        let result = PersonSet()

        for element in elements {
            for child in element.person.sons(in: index) {
                result.insert(child)
            }
        }
        return result
    }

    /// Return the daughters PersonSet of a PersonSet.
    ///
    public func daughters(in index: RecordIndex) -> PersonSet {

        let result = PersonSet()

        for element in elements {
            for child in element.person.daughters(in: index) {
                result.insert(child)
            }
        }
        return result
    }

    /// Return the brothers PersonSet of a PersonSet.
    ///
    public func brothers(in index: RecordIndex) -> PersonSet {

        let result = PersonSet()

        for element in elements {
            for child in element.person.brothers(in: index) {
                result.insert(child)
            }
        }
        return result
    }

    /// Return the sisters PersonSet of a PersonSet.
    ///
    public func sisters(in index: RecordIndex) -> PersonSet {

        let result = PersonSet()

        for element in elements {
            for child in element.person.sisters(in: index) {
                result.insert(child)
            }
        }
        return result
    }
}

extension PersonSet {

    /// Return the husbands PersonSet of a PersonSet.
    ///
    public func husbands(in index: RecordIndex) -> PersonSet {

        let result = PersonSet()

        for element in elements {
            for child in element.person.husbands(in: index) {
                result.insert(child)
            }
        }
        return result
    }

    /// Return the wives PersonSet of a PersonSet.
    ///
    public func wives(in index: RecordIndex) -> PersonSet {

        let result = PersonSet()

        for element in elements {
            for child in element.person.wives(in: index) {
                result.insert(child)
            }
        }
        return result
    }
}
