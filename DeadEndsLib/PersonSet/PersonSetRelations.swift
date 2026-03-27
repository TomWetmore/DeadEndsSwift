//
//  PersonSetRelations.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 22 March 2026.
//  Last changed on 22 March 2026.
//

import Foundation

extension PersonSet {

    func children() -> PersonSet {

        var results = PersonSet()
        return results
    }

    func spouses() -> PersonSet {
        var results = PersonSet()
        return results
    }

    func siblings() -> PersonSet {
        var results = PersonSet()
        return results
    }

    /// Return the ancestors person set of a person set.
    func ancestorsSet(in index: RecordIndex) -> PersonSet {
            var visited: Set<RecordKey> = []
            var result: [Root] = []

            for element in elements {
                for ancRoot in index.ancestors(of: element.root) {
                    let ancKey = requireKey(on: ancRoot)
                    if visited.insert(ancKey).inserted {
                        result.append(ancRoot)
                    }
                }
            }
            return PersonSet(roots: result)
        }

    /// Return the descendants person set of a person set.
    func descendantsSet(in index: RecordIndex) -> PersonSet {
        var visited: Set<RecordKey> = []
        var result: [Root] = []

        for element in elements {
            for descRoot in index.descendants(of: element.root) {
                let descKey = requireKey(on: descRoot)
                if visited.insert(descKey).inserted {
                    result.append(descRoot)
                }
            }
        }
        return PersonSet(roots: result)
    } 
}
