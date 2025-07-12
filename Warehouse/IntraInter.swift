//
//  IntraInter.swift
//  Warehouse
//
//  Created by Thomas Wetmore on 12 July 2025.
//  Last changed on 12 July 2025.
//

import Foundation
import DeadEndsLib // Remove if file is added to the DeadEndsLib


// ChatGPT's second refinement: it says it's a little cleaner that deep if/lets, while
// it preserves clarity.

extension GedcomNode {
    func father(index: RecordIndex) -> GedcomNode? {
        guard let famKey = child(withTag: "FAMC")?.value,
              let fam = index[famKey],
              let husbKey = fam.child(withTag: "HUSB")?.value
        else { return nil }

        return index[husbKey]
    }
}

extension GedcomNode {
    /// Follow a path of tags through the node and the record index.
    /// Example: ["FAMC", "HUSB"] from an INDI node gives you the father.
    func traverse(tags: [String], index: RecordIndex) -> GedcomNode? {
        var node: GedcomNode? = self
        for tag in tags {
            guard let current = node,
                  let child = current.child(withTag: tag),
                  let key = child.value,
                  let next = index[key] else {
                return nil
            }
            node = next
        }
        return node
    }
}


// Examples:
/*
 let dad = person.traverse(tags: ["FAMC", "HUSB"], index: recordIndex)
 let mom = person.traverse(tags: ["FAMC", "WIFE"], index: recordIndex)
 */

// Define more specific in terms of the traverse idea.
extension GedcomNode {
    func father3(index: RecordIndex) -> GedcomNode? {
        traverse(tags: ["FAMC", "HUSB"], index: index)
    }

    func mother(index: RecordIndex) -> GedcomNode? {
        traverse(tags: ["FAMC", "WIFE"], index: index)
    }
}

// More detailed traversal that can go both in and between records:

enum Step {
    case tag(String)         // Simple tag link within the same record
    case follow(String)      // Tag whose value is a cross-ref key
}

extension GedcomNode {
    func traverse(path: [Step], index: RecordIndex) -> GedcomNode? {
        var node: GedcomNode? = self
        for step in path {
            switch step {
            case .tag(let t):
                node = node?.child(withTag: t)
            case .follow(let t):
                guard let value = node?.child(withTag: t)?.value else { return nil }
                node = index[value]
            }
        }
        return node
    }
}

// EXAMPLES
/*
 let dad = person.traverse(path: [.follow("FAMC"), .follow("HUSB")], index: index)
 let bdate = person.traverse(path: [.tag("BIRT"), .tag("DATE")], index: index)?.value
 */

// ALREADY HAVE THIS:

extension GedcomNode {
    func node(withPath path: [String]) -> GedcomNode? {
        guard !path.isEmpty else { return nil }
        return path.reduce(into: Optional(self)) { node, tag in
            node = node?.child(withTag: tag)
        }
    }
}

// COULD ADD:

extension GedcomNode {
    func nodes(matchingPath path: [String]) -> [GedcomNode] {
        guard !path.isEmpty else { return [] }
        var nodes: [GedcomNode] = [self]
        for tag in path {
            nodes = nodes.flatMap { node in
                node.children(withTag: tag)
            }
        }
        return nodes
    }
}

// Cleaned up extensible base:

enum LinkStep {
    case follow(String) // follows a tag whose value is a cross-ref key
    case tag(String)    // gets child with tag
}

extension GedcomNode {
    func follow(path: [LinkStep], index: RecordIndex) -> GedcomNode? {
        var node: GedcomNode? = self
        for step in path {
            switch step {
            case .tag(let tag):
                node = node?.child(withTag: tag)
            case .follow(let tag):
                guard let key = node?.child(withTag: tag)?.value else { return nil }
                node = index[key]
            }
        }
        return node
    }
}

// EXAMPLES
/*
 let father = person.follow(path: [.follow("FAMC"), .follow("HUSB")], index: index)
 let birthDate = person.follow(path: [.tag("BIRT"), .tag("DATE")], index: index)?.value
 */


// Could define "Presets"

extension GedcomNode {
    func father4(index: RecordIndex) -> GedcomNode? {
        follow(path: [.follow("FAMC"), .follow("HUSB")], index: index)
    }

    func mother3(index: RecordIndex) -> GedcomNode? {
        follow(path: [.follow("FAMC"), .follow("WIFE")], index: index)
    }

    func firstSpouseFamily(index: RecordIndex) -> GedcomNode? {
        child(withTag: "FAMS")?.value.flatMap { key in index[key] }
    }
}



