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
        
        var seen: Set<RecordKey> = []
        var roots: [Root] = []

        for element in elements {
            for chilRoot in index.children(ofPersonRoot: element.root) {
                let chilKey = requireKey(on: chilRoot)
                if seen.insert(chilKey).inserted {
                    roots.append(chilRoot)
                }
            }
        }
        return PersonSet(roots: roots)
    }

    /// Return the parent person set of a person set. The result may
    /// overlap with self.
    public func parentsSet(in index: RecordIndex) -> PersonSet<Payload> {

        var seen = Set<RecordKey>()
        let result = PersonSet<Payload>()

        for element in elements {
            let keys = index.parentKeys(ofPersonKey: element.key)
            for key in keys where seen.insert(key).inserted {
                let root = index.requireRoot(from: key, tag: GedcomTag.INDI)
                result.append(root)
            }
        }
    }

    /// Return the set of all spouses of persons in this set.
    /// The result may overlap with self.
    public func spouseSet(in index: RecordIndex) -> PersonSet<Payload> {

        var seen = Set<RecordKey>()
        let result = PersonSet<Payload>()

        for element in elements {
            let keys = index.spouseKeys(ofPersonKey: element.key)
            for key in keys where seen.insert(key).inserted {
                let root = index.requireRoot(from: key, tag: GedcomTag.INDI)
                result.append(root)
            }
        }
        return result
    }

    /// Return the sibling person set of a person set.
    public func siblingSet(in index: RecordIndex) -> PersonSet<Payload> {

        var seen = Set<RecordKey>()
        let result = PersonSet<Payload>()

        for element in elements {
            let keys = index.siblingKeys(ofPersonKey: element.key)
            for key in keys where seen.insert(key).inserted {
                let root = index.requireRoot(from: key, tag: GedcomTag.INDI)
                result.append(root)

            }
        }
        return result
    }

    /// Return the ancestors person set of a person set.
    func ancestorSet(in index: RecordIndex) -> PersonSet<Payload> {
        var visited: Set<RecordKey> = []
        var roots: [Root] = []

        for element in elements {
            for ancRoot in index.ancestors(of: element.root) {
                let ancKey = requireKey(on: ancRoot)
                if visited.insert(ancKey).inserted {
                    roots.append(ancRoot)
                }
            }
        }
        return PersonSet(roots: roots)
    }

    /// Return the descendants person set of a person set.
    func descendantSet(in index: RecordIndex) -> PersonSet<Payload> {
        var visited: Set<RecordKey> = []
        var roots: [Root] = []

        for element in elements {
            for descRoot in index.descendants(of: element.root) {
                let descKey = requireKey(on: descRoot)
                if visited.insert(descKey).inserted {
                    roots.append(descRoot)
                }
            }
        }
        return PersonSet(roots: roots)
    }
}

