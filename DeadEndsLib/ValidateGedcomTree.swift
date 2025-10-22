//
//  ValidateGedcomTree.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 4 October 2025.
//  Last changed on 4 October 2025.
//

import Foundation

/// Validate the integrity of a GEDCOM subtree.
/// - Parameters:
///   - root: The root node to validate.
///   - seen: Internal set to track visited nodes (for cycle detection).
/// - Returns: An array of error messages. Empty = valid.
public func validateTree(root: GedcomNode, seen: inout Set<ObjectIdentifier>) -> [String] {
    var errors: [String] = []
    let id = ObjectIdentifier(root)

    // Cycle check
    if seen.contains(id) {
        errors.append("Cycle detected at node \(root.tag) \(root.val ?? "")")
        return errors
    }
    seen.insert(id)

    // Kids sanity check
    if let kid = root.kid {
        if kid.dad !== root {
            errors.append("Child \(kid.tag) does not have correct parent pointer")
        }
        var curr: GedcomNode? = kid
        while let node = curr {
            errors.append(contentsOf: validateTree(root: node, seen: &seen))
            curr = node.sib
            if curr != nil && curr?.dad !== root {
                errors.append("Sibling \(curr!.tag) does not point back to parent \(root.tag)")
            }
        }
    }

    return errors
}

/// Convenience wrapper
public func validateTree(root: GedcomNode) -> [String] {
    var seen = Set<ObjectIdentifier>()
    return validateTree(root: root, seen: &seen)
}
