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

    /// Separate list person roots from a record index into a partition ([[Root]])
    /// based on FAMC, FAMS, HUSB, WIFE, and CHIL links.
    public func partitions(personRoots: [Root], includeFamilies: Bool = false) -> [[Root]] {
        var visited: Set<RecordKey> = []
        var partitions: [[Root]] = []

        for root in personRoots {
            guard let key = root.key else { fatalError("root without key") }
            guard !visited.contains(key) else { continue }
            let partition = partition(with: root, visited: &visited, includeFamilies: includeFamilies)
            partitions.append(partition)
        }
        return partitions
    }

    /// Find the partition a person (via its root node) belongs to. The result is an array of person
    /// roots. If includeFamilies is true family roots are included in the results.
    func partition(with personRoot: Root, visited: inout Set<RecordKey>,
                   includeFamilies: Bool = false) -> [Root] {
        var result: [Root] = []
        var queue: [Root] = [personRoot]
        var next = 0

        // Process each person root on the queue.
        while next < queue.count {
            let root = queue[next]
            next += 1
            guard let key = root.key else { fatalError("root without key") }
            if visited.contains(key) { continue }
            visited.insert(key)

            switch root.tag {
            case GedcomTag.INDI: result.append(root)
            case GedcomTag.FAM:  if includeFamilies { result.append(root) }
            default: break
            }
            // TODO: We should be prepared for FAMS and FAMC tags in familes, and
            // HUSB, WIFE and CHIL tags in persons.
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
        return result
    }
}
