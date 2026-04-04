//
//  ValidateGedcomTree.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 4 October 2025.
//  Last changed on 2 April 2026.
//

import Foundation

/// Validate a node tree. Returns an array of error messages. If the
/// array is empty the tree is valid. This checks the internal structure
/// of a single tree. It does not check semantics or relations with other
/// trees.
public func validateTree(root: Root) -> [String] {
    var seen = Set<ObjectIdentifier>()
    return validateTree(node: root, seen: &seen)
}

/// Recursive helper validator function.
public func validateTree(node: GedcomNode, seen: inout Set<ObjectIdentifier>) -> [String] {
    var errors: [String] = []
    let id = ObjectIdentifier(node)

    if seen.contains(id) {
        errors.append("cycle detected at node \(node.tag) \(node.val ?? "")")
        return errors
    }
    seen.insert(id)
    if let kid = node.kid {
        if kid.dad !== node {
            errors.append("Child \(kid.tag) does not have correct dad pointer")
        }
        var curr: GedcomNode? = kid
        while let node = curr {
            errors.append(contentsOf: validateTree(node: node, seen: &seen))
            curr = node.sib
            if curr != nil && curr?.dad !== node {
                errors.append("sibling \(curr!.tag) does not point back to parent \(node.tag)")
            }
        }
    }
    return errors
}
