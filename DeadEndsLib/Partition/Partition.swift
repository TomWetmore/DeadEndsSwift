//
//  Partition.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 16 March 2026.
//  Last changed on 16 March 2026.

/// Contains functions that partitions persons from a GNodeList into a List of
/// RootLists of persons in closed sets based on FAMS, FAMC, HUSB, WIFE & CHIL
/// relationships.

import Foundation

/// Partition a person RootList into a partition [RootList] of persons. Each partition
/// is a closed set based on FAMS, FAMC, HUSB, WIFE and CHIL links.
///
extension RecordIndex {

    public func getPartitions(persons: [Root]/*, index: MyRecordIndex*/) -> [[Root]] {
        var visited: Set<RecordKey> = []
        var partitions: [[Root]] = []

        for root in persons {
            guard let key = root.key else { fatalError("root without key") }
            guard !visited.contains(key) else { continue }
            let partition = createPartition(root: root, /*index: index,*/ visited: &visited)
            partitions.append(partition)
        }
        return partitions
    }

    /// Return closed of set of persons the argument person belongs to.
    func createPartition(root: Root, /*index: MyRecordIndex,*/ visited: inout Set<RecordKey>) -> [Root] {
        var partition: [Root] = []
        var queue: [Root] = [root]

        while !queue.isEmpty {
            let root = queue.removeLast()  // Really behaves like stack.
            guard let key = root.key else { fatalError("root without key") }
            if visited.contains(key) { continue }
            visited.insert(key)
            if root.tag == GedcomTag.INDI { partition.append(root) }  // Add persons, not families.

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
