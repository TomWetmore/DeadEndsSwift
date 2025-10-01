//
//  GedcomNode.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 18 Devember 2024.
//  Last changed on 25 September 2025.
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

    public var key: String?  // Optional key found on root lines.
    public var tag: String  // Tag mandatory on all lines.
    public var val: String? // Optional value.
    public var sib: GedcomNode?  // Next sibling.
    public var kid: GedcomNode?  // First child
    public weak var dad: GedcomNode? // Optional parent found on all non-roots.

    /// Description of GedcomNode.
    public var description: String {
        var description =  ""
        if let key { description += "\(key) " }
        description += "\(tag)"
        if let val { description += " \(val) " }
        return description
    }

    /// Creates a GedcomNode with key, tag and value.
    public init(key: String? = nil, tag: String, val: String? = nil) {
        self.key = key
        self.tag = tag
        self.val = val
    }

    /// 0-based depth of this node in its tree; corresponds to Gedcom level.
    public var lev: Int {
        var level = -1
        var node: GedcomNode? = self
        var safety = 100   // larger than realistic Gedcom depth.
        while let current = node, safety > 0 {
            level += 1
            node = current.dad
            safety -= 1
        }
        return level
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

    var kids: [GedcomNode]? {
        var results: [GedcomNode] = []
        var node = kid
        while let current = node {
            results.append(current)
            node = current.sib
        }
        return results.count == 0 ? nil : results
    }

    /// Returns the array of all of .self's children.
    func kiddies() -> [GedcomNode] {
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
    func kid(atPath path: [String]) -> GedcomNode? {
        guard !path.isEmpty else { return nil }
        return path.reduce(into: Optional(self)) { node, tag in
            node = node?.kid(withTag: tag)
        }
    }

    /// Traverses a squence of tags to find a descendant's value.
    func kidVal(atPath path: [String]) -> String? {
        path.reduce(self) { node, tag in node?.kid(withTag: tag) }?.val
    }
}

public extension GedcomNode {

    /// Converts a GedcomNode tree to Gedcom text. It is recursive and normally called on a Record root
    /// with level defaulted to 0 and indent to false. Sibs of the root are not included in the output.
    func gedcomText(level: Int = 0, indent: Bool = false) -> String {

        var lines: [String] = []

        let space = indent ? String(repeating: "  ", count: level) : ""
        var line = space + "\(level)"
        if level == 0, let k = self.key { line += " \(k)" }
        line += " \(self.tag)"
        if let value = self.val, !value.isEmpty { line += " \(value)" }
        lines.append(line)

        var child = self.kid
        while let node = child {
            lines.append(node.gedcomText(level: level + 1, indent: indent))
            child = node.sib
        }
        return lines.joined(separator: "\n")
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

public extension GedcomNode {

    /// Create and add a new child to this node.
    @discardableResult
    func addKid(tag: String, val: String? = nil) -> GedcomNode {
        let child = GedcomNode(tag: tag, val: val)
        return addKid(child)
    }

    /// Add an existing child node to this node's child list.
    @discardableResult
    func addKid(_ kid: GedcomNode) -> GedcomNode {
        kid.dad = self
        if self.kid == nil {
            self.kid = kid
        } else {
            self.lastKid()?.sib = kid
        }
        return kid
    }

    /// Find the last child in the list.
    func lastKid() -> GedcomNode? {
        var node = self.kid
        while let next = node?.sib {
            node = next
        }
        return node
    }
}

/// Extension that conforms GedcomNode to Identifiable.
extension GedcomNode: Identifiable {
    public var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }
}

