//
//  PersonSetRelations.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 22 March 2026.
//  Last changed on 27 March 2026.
//

import Foundation

extension PersonSet {

    /// Return the children person set of a person set.
    public func childrenSet(in index: RecordIndex) -> PersonSet {
        var visited: Set<RecordKey> = []
        var roots: [Root] = []

        for element in elements {
            for chilRoot in index.children(ofPersonRoot: element.root) {
                let chilKey = requireKey(on: chilRoot)
                if visited.insert(chilKey).inserted {
                    roots.append(chilRoot)
                }
            }
        }
        return PersonSet(roots: roots)
    }

    /// Return the spouses person set of a person set.
//    public func spousesSet() -> PersonSet {
//        var visited: Set<RecordKey> = []
//        var roots: [Root] = []
//
//        for element in elements {
//            for spouseRoot in index.spouses(ofPersonRoot: element.root) {
//                let spouseKey = requireKey(on: spouseRoot)
//                if visited.insert(spouseKey).inserted {
//                    roots.append(spouseRoot)
//                }
//            }
//        }
//        return PersonSet(roots: roots)
//    }

    /// Return the sibllings person set of a person set.
    func siblingsSet() -> PersonSet {
        var results = PersonSet()
        return results
    }

    /// Return the ancestors person set of a person set.
    func ancestorsSet(in index: RecordIndex) -> PersonSet {
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
    func descendantsSet(in index: RecordIndex) -> PersonSet {
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
