//
//  Partition.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 16 March 2026.
//  Last changed on 17 March 2026.
//

import Foundation

/// Separate a list of persons ([Root]) into a partition ([[Root]]) of persons and
/// optionally families. Each partition is a closed set based on FAMS, FAMC, HUSB,
/// WIFE and CHIL links.

extension Database {

    /// Separate list of all person roots in a database to a closed partition.
    public func partitions(includeFamilies: Bool = false) -> [[Root]] {
        recordIndex.partitions(personRoots: self.persons, includeFamilies: includeFamilies)
    }
}
extension RecordIndex {

    /// Separate a list of person roots into closed partitions.
    public func partitions(personRoots: [Root], includeFamilies: Bool = false) -> [[Root]] {
        var visited: Set<RecordKey> = []
        var partitions: [[Root]] = []

        for root in personRoots {
            guard let key = root.key else { fatalError("root without key") }
            guard !visited.contains(key) else { continue }
            let partition = createPartition(root: root, visited: &visited, includeFamilies: includeFamilies)
            partitions.append(partition)
        }
        return partitions
    }

    /// Create the partition the argument person root belongs to.
    func createPartition(root: Root, visited: inout Set<RecordKey>, includeFamilies: Bool) -> [Root] {
        var partition: [Root] = []
        var queue: [Root] = [root]

        while !queue.isEmpty {
            let root = queue.removeLast()  // Stack behavior.
            guard let key = root.key else { fatalError("root without key") }
            if visited.contains(key) { continue }
            visited.insert(key)
            switch root.tag {
            case GedcomTag.INDI: partition.append(root)
            case GedcomTag.FAM:  if includeFamilies { partition.append(root) }
            default: break
            }

            for kid in root.kids {
                switch kid.tag {
                case GedcomTag.FAMS, GedcomTag.FAMC:
                    guard let val = kid.val, let family = self[val]
                    else { fatalError(" value must be a valid family key") }
                    queue.append(family)
                case GedcomTag.HUSB, GedcomTag.WIFE, GedcomTag.CHIL:
                    guard let val = kid.val, let person = self[val]
                    else { fatalError(" value must be a valid person key") }
                    queue.append(person)
                default:
                    break
                }
            }
        }
        return partition
    }
}
