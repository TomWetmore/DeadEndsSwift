//
//  Partition.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 16 March 2026.
//  Last changed on 21 March 2026.
//

import Foundation

extension Database {

    /// Separate list person roots from a database into a partition ([[Root]]) based
    /// on FAMC, FAMS, HUSB, WIFE, and CHIL links.
    public func partitions(includeFamilies: Bool = false) -> [[Root]] {
        recordIndex.partitions(personRoots: self.persons, includeFamilies: includeFamilies)
    }
}

extension RecordIndex {

    /// Separate a list of person roots into a partition based on FAMC, FAMS,
    /// HUSB, WIFE, and CHIL links. It is assumed that the list of persons is
    /// genealogically closed, but this is not actually required.
    public func partitions(personRoots: [Root],
                           includeFamilies: Bool = false) -> [[Root]] {
        var visited: Set<RecordKey> = []  // Record keys that have been seen.
        var partitions: [[Root]] = []  // Array of partitions to be returned.

        // Get the next person root
        for root in personRoots {
            // If the key has been seen before this root and all those related
            // to it are already in a partition.
            let key = requireKey(on: root)
            if visited.contains(key) { continue }
            // The key has not been seen before so create its partition
            let partition = partition(containing: root, visited: &visited,
                                      includeFamilies: includeFamilies)
            partitions.append(partition)
        }
        return partitions
    }

    /// Find the partition a person root belongs to. The result is an array of
    /// person roots. If includeFamilies is true family roots are also included.
    func partition(containing personRoot: Root, visited: inout Set<RecordKey>,
                   includeFamilies: Bool = false) -> [Root] {
        var result: [Root] = []
        // The queue of root nodes holds person and family roots.
        var queue: [Root] = [personRoot]
        var next = 0

        // Process each root on the queue.
        while next < queue.count {
            let root = queue[next]
            next += 1
            // If root's key has been seen before continue to next root.
            let key = requireKey(on: root)
            if visited.contains(key) { continue }

            // Seeing node and key for the first time.
            visited.insert(key)
            // The root can be a person or family; keep track for below.
            let rootTag = root.tag
            // Add root to the partition.
            switch rootTag {
            case GedcomTag.INDI: result.append(root)
            case GedcomTag.FAM: if includeFamilies { result.append(root) }
            default: break
            }
            // Look for linking tags FAMC, FAMS, HUSB, WIFE, and CHIL in the
            // current person or family.
            for kid in root.kids {
                switch kid.tag {
                case GedcomTag.FAMS, GedcomTag.FAMC:
                    if rootTag == GedcomTag.INDI {
                        queue.append(requireRoot(from: kid, tag: GedcomTag.FAM))
                    }
                case GedcomTag.HUSB, GedcomTag.WIFE, GedcomTag.CHIL:
                    if rootTag == GedcomTag.FAM {
                        queue.append(requireRoot(from: kid, tag: GedcomTag.INDI))
                    }
                default:
                    break
                }
            }
        }
        return result
    }
}
