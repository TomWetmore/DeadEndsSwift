//
//  PersonSetRelations.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 22 March 2026.
//  Last changed on 30 March 2026.
//

import Foundation

extension PersonSet {

    /// Return the children person set of a person set.
    public func childrenSet(in index: RecordIndex) -> PersonSet {
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

    /// Return the sibling person set of a person set.
    public func siblingSet(in index: RecordIndex) -> PersonSet {
        var seen = Set<RecordKey>()
        var result: [Root] = []

        for element in self.elements {
            let key = element.key  // Not optional
            for sibKey in index.siblingKeys(ofPersonKey: key) {
                if seen.insert(sibKey).inserted {
                    result.append(index.requireRoot(from: sibKey, tag: GedcomTag.INDI))
                }
            }
        }
        return PersonSet(roots: result)
    }

    /// Return the ancestors person set of a person set.
    func ancestorSet(in index: RecordIndex) -> PersonSet {
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
    func descendantSet(in index: RecordIndex) -> PersonSet {
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

extension RecordIndex {
    func siblingKeys(ofPersonKey key: RecordKey) -> [RecordKey] {
        let root = requireRoot(from: key, tag: GedcomTag.INDI)
        var result: [RecordKey] = []

        for famc in root.kids(withTag: GedcomTag.FAMC) {
            let famRoot = requireRoot(from: famc, tag: GedcomTag.FAM)
            for childNode in famRoot.kids(withTag: GedcomTag.CHIL) {
                let childRoot = requireRoot(from: childNode, tag: GedcomTag.INDI)
                let childKey = requireKey(on: childRoot)
                if childKey != key {
                    result.append(childKey)
                }
            }
        }
        return dedupeKeys(result)
    }
}
