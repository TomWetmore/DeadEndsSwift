//
//  Connect.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 16 March 2026.
//  Last changed on 19 March 2026.
//

import Foundation

/// Data collected per person key.
public struct ConnectData {
    var ancestors: Int? = nil
    var descendants: Int? = nil
}

public typealias ConnectIndex = [RecordKey: ConnectData]

/// Get numbers of ancestors and descendants for persons in a closed partition.
extension RecordIndex {

    /// Find connection data for a list of root nodes. The list must contain
    /// all persons from a closed partition based on FAMC, FAMS, HUSB, WIFE,
    /// and CHIL links. If the list does not contain a closed partition there
    /// is no guarantee that all connect data will be accurate.
    public func connections(partition: [Root]) -> ConnectIndex {
        var connectIndex: ConnectIndex = [:]
        for root in partition {
            guard let key = root.key, root.tag == GedcomTag.INDI else { continue }
            connectIndex[key] = ConnectData()
        }
        for root in partition {
            connections(root: root, connectIndex: &connectIndex)
        }
        return connectIndex
    }

    /// Find connection data for a person which includes finding the
    /// connection data for the person's ancestors and descendants.
    func connections(root: Root, connectIndex: inout ConnectIndex) {
        guard let key = root.key, root.tag == GedcomTag.INDI
        else { return }

        var data = connectIndex[key]!
        if data.ancestors == nil {
            data.ancestors = numAncestors(of: key, connectIndex: &connectIndex)
        }
        if data.descendants == nil {
            data.descendants = numDescendants(of: key, connectIndex: &connectIndex)
        }
        connectIndex[key] = data
    }

    /// Find number of ancestors of a person which includes finding the number
    /// of ancestors for all ancestors.
    func numAncestors(of key: RecordKey, connectIndex: inout ConnectIndex) -> Int {

        if let known = connectIndex[key]!.ancestors { return known }
        var result = 0
        for pkey in self.parentKeys(of: key) {
            result += 1 + numAncestors(of: pkey, connectIndex: &connectIndex)
        }
        var data = connectIndex[key]!
        data.ancestors = result
        connectIndex[key] = data
        return result
    }

    /// Find number of descendants of a person which includes finding the number
    /// of descendants of all descendants.
    func numDescendants(of key: RecordKey, connectIndex: inout ConnectIndex) -> Int {

        if let known = connectIndex[key]!.descendants { return known }
        var result = 0
        for ckey in self.childrenKeys(of: key) {
            result += 1 + numDescendants(of: ckey, connectIndex: &connectIndex)
        }
        var data = connectIndex[key]!
        data.descendants = result
        connectIndex[key] = data
        return result
    }
}

extension RecordIndex {

    /// Find all ancestors of a person; argument and results are root nodes.
    public func ancestors(of personRoot: Root) -> [Root] {
        guard let startKey = personRoot.key
        else { fatalError("INDI record must have a key") }
        var visited: Set<RecordKey> = []
        var queue: [RecordKey] = parentKeys(of: startKey)
        var next = 0
        var result: [GedcomNode] = []
        
        while next < queue.count {
            let key = queue[next]
            next += 1
            guard !visited.contains(key) else { continue }
            visited.insert(key)
            // Look up the record root that this key refers to.
            guard let root = self[key] else {
                fatalError("cannot lookup up a record in the index")
            }
            // Append that record root to the results list.
            result.append(root)
            queue.append(contentsOf: parentKeys(of: key))
        }
        return result
    }

    /// Find all ancestors of a person. Argument and results are person structures.
    public func ancestors(of person: Person) -> [Person] {
        let roots = ancestors(of: person.root)
        return roots.compactMap { $0.key.flatMap { self.person(for: $0) } }
    }

    /// Return number of ancestors of a person; argument is a person root.
    public func numAncestors(of personRoot: Root) -> Int {
        return ancestors(of: personRoot).count
    }

    /// Return number of ancestors of a person; argument is a person structure.
    public func numAncestors(of person: Person) -> Int {
        ancestors(of: person.root).count
    }
}

extension RecordIndex {

    /// Find all descendants of a person; argument and results are person roots.
    public func descendants(of personRoot: Root) -> [Root] {
        guard let startKey = personRoot.key else {
            fatalError("INDI node must have a key")
        }
        var visited: Set<RecordKey> = []
        var queue: [RecordKey] = childrenKeys(of: startKey)
        var next = 0
        var result: [Root] = []

        while next < queue.count {
            let key = queue[next]
            next += 1
            guard !visited.contains(key) else { continue }
            visited.insert(key)

            guard let root = self[key]
            else { fatalError("cannot lookup up a record in the index") }

            result.append(root)
            queue.append(contentsOf: childrenKeys(of: key))
        }
        return result
    }

    /// Find all descendants of a person; argument and results are person structures.
    public func descendants(of person: Person) -> [Person] {
        let roots = descendants(of: person.root)
        return roots.compactMap { $0.key.flatMap { self.person(for: $0) } }
    }

    /// Return number of descendants of a person; argument is a person root.
    public func numDescendants(of personRoot: Root) -> Int {
        return descendants(of: personRoot).count
    }

    /// Return number of descendants of a person; argument is a person structure.
    public func numDescendants(of person: Person) -> Int {
        descendants(of: person.root).count
    }
}

extension RecordIndex {

    /// Return the keys of the parents of a person.
    func parentKeys(of personKey: RecordKey) -> [RecordKey] {
        guard let root = self[personKey], root.tag == GedcomTag.INDI
        else { fatalError("parentKeys called with non-person key") }
        var result: [RecordKey] = []

        for famc in root.kids(withTag: GedcomTag.FAMC) {
            guard let famKey = famc.val,
                  let famRoot = self[famKey],
                  famRoot.tag == GedcomTag.FAM
            else { fatalError("invalid FAMC link") }

            for parentNode in famRoot.kids(withTags: [GedcomTag.HUSB, GedcomTag.WIFE]) {
                if let parentKey = parentNode.val {
                    result.append(parentKey)
                }
            }
        }
        return result
    }

    /// Return the keys of the children of a person.
    func childrenKeys(of personKey: RecordKey) -> [RecordKey] {
        guard let root = self[personKey], root.tag == GedcomTag.INDI
        else { fatalError("childrenKeys called with non-person key") }
        var result: [RecordKey] = []
        for fams in root.kids(withTag: GedcomTag.FAMS) {
            guard let famKey = fams.val,
                  let famRoot = self[famKey],
                  famRoot.tag == GedcomTag.FAM
            else { fatalError("invalid FAMS link") }

            for childNode in famRoot.kids(withTag: GedcomTag.CHIL) {
                if let childKey = childNode.val {
                    result.append(childKey)
                }
            }
        }
        return result
    }
}
