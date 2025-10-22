//
//  GedcomTreeValidator.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 10/21/25.
//

import Foundation
import DeadEndsLib

/// Checks consistency of a GedcomNode tree:
/// - Every node’s `dad` is correct.
/// - All siblings share the same `dad`.
/// - No cycles in the tree.
struct GedcomTreeValidator {
    
    struct Error: CustomStringConvertible {
        let node: GedcomNode
        let message: String
        var description: String {
            "Error at node \(node.tag): \(message)"
        }
    }

    private var seen = Set<UUID>()

    private(set) var errors: [Error] = []

    mutating func validate(root: GedcomNode) -> Bool {
        errors.removeAll()
        seen.removeAll()
        dfs(node: root, expectedParent: nil)
        return errors.isEmpty
    }

    private mutating func dfs(node: GedcomNode, expectedParent: GedcomNode?) {

        if seen.contains(node.id) {
            errors.append(.init(node: node, message: "Cycle detected"))
            return
        }
        seen.insert(node.id)

        // Check parent pointer
        if node.dad !== expectedParent {
            errors.append(.init(node: node, message: "Incorrect parent reference"))
        }

        // Traverse children
        var child = node.kid
        while let current = child {
            if current.dad !== node {
                errors.append(.init(node: current, message: "Child’s dad does not match parent"))
            }
            dfs(node: current, expectedParent: node)

            // Check sibling parent linkage
            if let sibling = current.sib, sibling.dad !== node {
                errors.append(.init(node: sibling, message: "Sibling’s dad does not match parent"))
            }

            child = current.sib
        }
    }
}
/// EXAMPLE OF USE:
/*
 var validator = GedcomTreeValidator()
 let isValid = validator.validate(root: someGedcomNode)

 if !isValid {
     for error in validator.errors {
         print(error)
     }
 }
 */

