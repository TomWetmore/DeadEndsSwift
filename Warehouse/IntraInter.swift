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



enum TraversalStep {
    case tag(String)             // Intra-record descent to a child tag
    case follow(String)          // Inter-record pointer dereference
    case followAll(String)       // Follow all tags with this label (1-to-many links)
}

extension GedcomNode {
    /// Traverses through this node following the path and returns the first node matching the predicate.
    func firstMatch(
        path: [TraversalStep],
        index: RecordIndex,
        where predicate: (GedcomNode) -> Bool
    ) -> GedcomNode? {
        func search(from node: GedcomNode, remaining: ArraySlice<TraversalStep>) -> GedcomNode? {
            guard let step = remaining.first else {
                return predicate(node) ? node : nil
            }

            let nextSteps = remaining.dropFirst()

            switch step {
            case .tag(let tag):
                guard let child = node.child(withTag: tag) else { return nil }
                return search(from: child, remaining: nextSteps)

            case .follow(let tag):
                guard let key = node.child(withTag: tag)?.value,
                      let next = index[key] else { return nil }
                return search(from: next, remaining: nextSteps)

            case .followAll(let tag):
                let keys = node.children(withTag: tag).compactMap { $0.value }
                for key in keys {
                    if let next = index[key],
                       let match = search(from: next, remaining: nextSteps) {
                        return match
                    }
                }
                return nil
            }
        }

        return search(from: self, remaining: path[...])
    }
}

extension GedcomNode {
    /// Same as `firstMatch`, but returns the `.value` of the matched node.
    func firstValue(
        path: [TraversalStep],
        index: RecordIndex,
        where predicate: (GedcomNode) -> Bool
    ) -> String? {
        return firstMatch(path: path, index: index, where: predicate)?.value
    }
}

//--------------------- ANOTHER IMPLEMENTATION ------------------

//enum TraversalStep2 {
//    case tag(String)             // Child tag within current node
//    case follow(String)          // Cross-ref to another record
//    case followAll(String)       // Follow multiple refs (e.g., FAMS)
//}

struct TraversalPath {
    let steps: [TraversalStep]

    init(_ steps: [TraversalStep]) {
        self.steps = steps
    }

    func appending(_ step: TraversalStep) -> TraversalPath {
        TraversalPath(steps + [step])
    }

    static func tag(_ t: String) -> TraversalPath {
        TraversalPath([.tag(t)])
    }

    static func follow(_ t: String) -> TraversalPath {
        TraversalPath([.follow(t)])
    }

    static func followAll(_ t: String) -> TraversalPath {
        TraversalPath([.followAll(t)])
    }

    func tag(_ t: String) -> TraversalPath { appending(.tag(t)) }
    func follow(_ t: String) -> TraversalPath { appending(.follow(t)) }
    func followAll(_ t: String) -> TraversalPath { appending(.followAll(t)) }
}

protocol GedcomNavigator {
    var recordIndex: RecordIndex { get }

    func traverse(from root: GedcomNode, path: TraversalPath) -> GedcomNode?
    func firstMatch(from root: GedcomNode, path: TraversalPath, where predicate: (GedcomNode) -> Bool) -> GedcomNode?
    func firstValue(from root: GedcomNode, path: TraversalPath, where predicate: (GedcomNode) -> Bool) -> String?
    func allMatches(from root: GedcomNode, path: TraversalPath) -> [GedcomNode]
}


extension GedcomNavigator {
    func traverse(from root: GedcomNode, path: TraversalPath) -> GedcomNode? {
        var current: GedcomNode? = root
        for step in path.steps {
            switch step {
            case .tag(let tag):
                current = current?.child(withTag: tag)

            case .follow(let tag):
                guard let key = current?.child(withTag: tag)?.value else { return nil }
                current = recordIndex[key]

            case .followAll:
                // Invalid in single-traversal context
                return nil
            }
        }
        return current
    }

    func firstMatch(from root: GedcomNode, path: TraversalPath, where predicate: (GedcomNode) -> Bool) -> GedcomNode? {
        func recurse(_ node: GedcomNode, _ remaining: ArraySlice<TraversalStep>) -> GedcomNode? {
            guard let step = remaining.first else {
                return predicate(node) ? node : nil
            }

            let tail = remaining.dropFirst()
            switch step {
            case .tag(let tag):
                if let child = node.child(withTag: tag) {
                    return recurse(child, tail)
                }

            case .follow(let tag):
                if let key = node.child(withTag: tag)?.value,
                   let target = recordIndex[key] {
                    return recurse(target, tail)
                }

            case .followAll(let tag):
                let keys = node.children(withTag: tag).compactMap { $0.value }
                for key in keys {
                    if let target = recordIndex[key],
                       let match = recurse(target, tail) {
                        return match
                    }
                }
            }

            return nil
        }

        return recurse(root, path.steps[...])
    }

    func firstValue(from root: GedcomNode, path: TraversalPath, where predicate: (GedcomNode) -> Bool) -> String? {
        firstMatch(from: root, path: path, where: predicate)?.value
    }

    func allMatches(from root: GedcomNode, path: TraversalPath) -> [GedcomNode] {
        // Future: support collecting all matches if `followAll` is present
        []
    }
}

/*
 let path = TraversalPath.follow("FAMC").follow("HUSB")
 let dad = navigator.traverse(from: person, path: path)

 let birthDate = navigator.firstValue(
     from: person,
     path: .tag("BIRT").tag("DATE"),
     where: { _ in true }
 )
 */
