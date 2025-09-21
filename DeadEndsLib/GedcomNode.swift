//
//  GedcomNode.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 18 Devember 2024.
//  Last changed on 20 September 2025.
//

import Foundation

/// [String: String] map that ensures only one copy of each tag is used per database.
public class TagMap {

    private var map: [String: String] = [:]

    func intern(tag: String) -> String {
        if let existing = map[tag] { return existing }
        map[tag] = tag
        return tag
    }
}

/// Class of Gedcom nodes. A GedcomNode represents a line in a Gedcom file. key, tag and
/// value are the key (cross reference identifier), tag, and value fields of the Gedcom line.
/// The line's level number is inferred when needed.
public class GedcomNode: CustomStringConvertible {

    public var key: String?  // Optional Gedcom key (cross reference id) found on root lines.
    public var tag: String  // Gedcom tag found on all lines.
    public var val: String? // Optional value found on many lines.
    public var sib: GedcomNode?  // Next sibling.
    public var kid: GedcomNode?  // First child line
    public weak var dad: GedcomNode? // Parent reference; all but root nodes.

    /// Description of GedcomNode.
    public var description: String {
        var description =  ""
        if let key { description += "\(key) " }
        description += "\(tag)"
        if let val { description += " \(val) " }
        return description
    }

    /// Creates a GedcomNode with key, tag and value.
    init(key: String? = nil, tag: String, value: String? = nil) {
        self.key = key
        self.tag = tag
        self.val = value
    }

    /// Prints a GedcomNode tree to stdout.
    func printTree(level: Int = 0, indent: String = "") {
        let space = String(repeating: indent, count: level)
        print("\(space)\(level) \(self)")
        kid?.printTree(level: level + 1, indent: indent)
        sib?.printTree(level: level, indent: indent)
    }

    /// Gets the Dictionary that maps tags to a node's kids that have the tag.
    lazy var kidsByTag: [String: [GedcomNode]] = {
        var result: [String: [GedcomNode]] = [:]
        var current = kid
        while let node = current {
            result[node.tag, default: []].append(node)
            current = node.sib
        }
        return result
    }()
}

// GedcomNode implements the Record protocol.
//extension GedcomNode: Record {
//    public var root: GedcomNode { self }
//}

// Methods that return child (kid) nodes or their values.
public extension GedcomNode {

    /// Returns the value of .self's first child with given tag.
    func kidVal(forTag tag: String) -> String? {
        var node = kid
        while let current = node {
            if current.tag == tag {
                return current.val
            }
            node = current.sib
        }
        return nil
    }

    /// Returns the list of all non-nil values from .self's children with the given tag.
    func kidVals(forTag tag: String) -> [String] {
        kids(withTag: tag).compactMap { $0.val }
    }

    /// Returns .self's first child node with given tag, if any.
    func kid(withTag tag: String) -> GedcomNode? {
        var node = kid
        while let current = node {
            if current.tag == tag {
                return current
            }
            node = current.sib
        }
        return nil
    }

    /// Returns the array of all of .self's children.
    func kids() -> [GedcomNode] {
        var results: [GedcomNode] = []
        var node = kid
        while let current = node {
            results.append(current)
            node = current.sib
        }
        return results
    }

    /// Returns array of all of .self's children with given tag.
    func kids(withTag tag: String) -> [GedcomNode] {
        var results: [GedcomNode] = []
        var node = kid
        while let current = node {
            if current.tag == tag {
                results.append(current)
            }
            node = current.sib
        }
        return results
    }

    // Traverses a sequence of tags to find a descendant node.
    func node(withPath path: [String]) -> GedcomNode? {
        guard !path.isEmpty else { return nil }
        return path.reduce(into: Optional(self)) { node, tag in
            node = node?.kid(withTag: tag)
        }
    }
}

public extension GedcomNode {

    /// Converts the GedcomNode tree rooted at self to Gedcom text. The method is recursive.
    /// It is normally called on a root node, with level defaulted to 0 and indent to false.
    /// if indent is true the text is indented two spaces per level.
    ///
    /// Other implementations of this algorithm may use a nonrecursive top method that calls a
    /// recursive helper.
    ///
    /// Parameters:
    /// - level is the Gedcom level of the node
    /// - indent indicates whether the text should be indented.
    func gedcomText(level: Int = 0, indent: Bool = false) -> String {

        var text: [String] = [] // Text to return.
        let space = indent ? String(repeating: "  ", count: level) : ""
        var line = space + "\(level)" // Start the line with its level.
        if level == 0 { // If level 0 (root node) add the key.
            line += " \(self.key)"
        }
        line += " \(tag)" // Add the tag.
        if let value = val, !value.isEmpty {
            line += " \(value)" // Add value.
        }
        text.append(line) // Set text to this node's line.
        var child = self.kid
        while let node = child {
            text.append(node.gedcomText(level: level + 1, indent: indent))
            child = node.sib
        }
        return text.joined(separator: "\n")
    }
}

 extension GedcomNode {

    /// Returns all GedcomNodes in a tree.
    public func descendants() -> [GedcomNode] {
        var result: [GedcomNode] = []
        func visit(_ node: GedcomNode?) {
            guard let node = node else { return }
            result.append(node)
            visit(node.kid)
            visit(node.sib)
        }
        visit(self)
        return result
    }
}


extension GedcomNode {
    var objectID: ObjectIdentifier { ObjectIdentifier(self) }
}
// Usage:
//ForEach(nodes, id: \.objectID) { node in ... }
