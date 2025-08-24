//
//  GedcomNode.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 18 Devember 2024.
//  Last changed on 31 July 2025.
//

import Foundation

/// `TagMap` is a `[String: String]` map that ensures that only one copy of each tag is found in a database.
public class TagMap {

    private var map: [String: String] = [:]

    func intern(tag: String) -> String {
        if let existing = map[tag] { return existing }
        map[tag] = tag
        return tag
    }
}

/// Class of Gedcom nodes. A `GedcomNode` represents a line in a Gedcom file. `key`, `tag` and
/// `value` are the key (*cross reference identifier*), tag, and value fields of the Gedcom line.
/// The line's level number is inferred when needed.
public class GedcomNode: CustomStringConvertible {

    /// Optional Gedcom key (*cross reference identifier*) found on root nodes.
    public var key: String?
    /// Gedcom tag found on all Gedcom lines.
    public var tag: String
    /// Optional Gedcom value found on many Gedcom lines.
    public var value: String? // Value; optional.
                              /// Optional reference to the next sibling of `self`.
    public var sibling: GedcomNode?
    /// Optional reference to the first child of `self`.
    public var child: GedcomNode?  // First child; optional.
    public weak var parent: GedcomNode? // Parent; not on root nodes.

    public var description: String {
        var description =  ""
        if let key { description += "\(key) " }
        description += "\(tag)"
        if let value { description += " \(value) " }
        return description
    }

    /// Creates a new GedcomNode with key, tag and value.
    init(key: String? = nil, tag: String, value: String? = nil) {
        self.key = key
        self.tag = tag
        self.value = value
    }

    /// Prints a `GedcomNode` tree to `stdout` -- for debugging.
    func printTree(level: Int = 0, indent: String = "") {
        let space = String(repeating: indent, count: level)
        print("\(space)\(level) \(self)")
        child?.printTree(level: level + 1, indent: indent)
        sibling?.printTree(level: level, indent: indent)
    }

    // Gets the dictionary of array of all child GedcomNodes indexed by tag.
    lazy var childrenByTag: [String: [GedcomNode]] = {
        var result: [String: [GedcomNode]] = [:]
        var current = child
        while let node = current {
            result[node.tag, default: []].append(node)
            current = node.sibling
        }
        return result
    }()

}

extension GedcomNode: Equatable {

    /// Compare two `GedcomNodes`.
    ///
    /// `GedcomNodes` are equivalent only if they are the *same* node.
    public static func == (lhs: GedcomNode, rhs: GedcomNode) -> Bool {
        return lhs === rhs // identity comparison
    }
}

extension GedcomNode: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

public extension GedcomNode {

    /// Returns the value of `.self`'s first child with given tag, if any.
    func value(forTag tag: String) -> String? {
        var node = child
        while let current = node {
            if current.tag == tag {
                return current.value
            }
            node = current.sibling
        }
        return nil
    }

    /// Returns the list of all non-nil values from children with the given tag.
    func values(forTag tag: String) -> [String] {
        children(withTag: tag).compactMap { $0.value }
    }

    /// Returns `.self`'s first child node with given tag, if any.
    func child(withTag tag: String) -> GedcomNode? {
        var node = child
        while let current = node {
            if current.tag == tag {
                return current
            }
            node = current.sibling
        }
        return nil
    }

    /// Returns array of all of `.self`'s children with given tag.
    func children(withTag tag: String) -> [GedcomNode] {
        var results: [GedcomNode] = []
        var node = child
        while let current = node {
            if current.tag == tag {
                results.append(current)
            }
            node = current.sibling
        }
        return results
    }

    // Traverses a sequence of tags to find a descendant node.
    func node(withPath path: [String]) -> GedcomNode? {
        guard !path.isEmpty else { return nil }
        return path.reduce(into: Optional(self)) { node, tag in
            node = node?.child(withTag: tag)
        }
    }
}

public extension GedcomNode {

    /// Converts the `GedcomNode` tree rooted at `self` to Gedcom text. The method is recursive.
    /// It is normally called on a root node, with `level` defaulted to `0` and `indent` to `false`.
    /// if `indent` is `true` the text is indented two spaces per level.
    ///
    /// Other implementations of this algorithm may use a nonrecursive *top* method that calls a
    /// recursive *helper*.
    ///
    /// Parameters:
    /// - `level` is the Gedcom level of the node
    /// - `indent` indicates whether the text should be indented.

    func gedcomText(level: Int = 0, indent: Bool = false) -> String {

        var text: [String] = [] // Text to return.
        let space = indent ? String(repeating: "  ", count: level) : ""
        var line = space + "\(level)" // Start the line with its level.
        if level == 0, let key = self.key { // If level 0 (root node) add the key.
            line += " \(key)"
        }
        line += " \(tag)" // Add the tag.
        if let value = value, !value.isEmpty {
            line += " \(value)" // Add value.
        }
        text.append(line) // Set text to this node's line.

        var child = self.child
        while let node = child {
            text.append(node.gedcomText(level: level + 1, indent: indent))
            child = node.sibling
        }

        return text.joined(separator: "\n")
    }
}

public extension GedcomNode {

    /// Returns all `GedcomNodes` in a tree.
    func descendants() -> [GedcomNode] {
        var result: [GedcomNode] = []
        func visit(_ node: GedcomNode?) {
            guard let node = node else { return }
            result.append(node)
            visit(node.child)
            visit(node.sibling)
        }
        visit(self)
        return result
    }
}

extension GedcomNode: Identifiable {
    public var id: String { key ?? UUID().uuidString } // root nodes always have a key
//    public static func == (lhs: GedcomNode, rhs: GedcomNode) -> Bool {
//        lhs.id == rhs.id
//    }
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//    }
}

