//
//  GedcomNode.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 18 Devember 2024.
//  Last changed on 1 October 2025.
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
public class GedcomNode: Identifiable, ObservableObject, CustomStringConvertible {

    public var id: UUID = UUID()
    public var key: String?  // Optional key found on root lines.
    @Published public var tag: String  // Tag mandatory on all lines.
    @Published public var val: String? // Optional value.
    public var sib: GedcomNode?  // Next sibling.
    public var kid: GedcomNode?  // First child
    public weak var dad: GedcomNode? // Optional parent found on all non-roots.

    /// Returns the Array of GedcomNode children of a parent node.
    public var kids: [GedcomNode] {
        var results: [GedcomNode] = []
        var node = kid
        while let current = node {
            results.append(current)
            node = current.sib
        }
        return results
    }

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



    /// Returns the Array of all .self's children with a given tag.
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

    /// Traverses the first sequence of specific tags to find a descendant node.
    func kid(atPath path: [String]) -> GedcomNode? {
        guard !path.isEmpty else { return nil }
        return path.reduce(into: Optional(self)) { node, tag in
            node = node?.kid(withTag: tag)
        }
    }

    /// Traverses the first sequence of specific tags to find a descendant node's value.
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

    func hasKids() -> Bool {
        return self.kid != nil
    }

    /// Create and add a new child to this node.
    @discardableResult
    func addKid(tag: String, val: String? = nil) -> GedcomNode {
        let child = GedcomNode(tag: tag, val: val)
        return addKid(child)
    }

    /// Add an existing kid node to be this node's first kid.
    @discardableResult
    func addKid(_ kid: GedcomNode) -> GedcomNode {
        print("GedcomNode.addKid called; new kid: \(kid)\n dad tree:")
        self.printTree(level: 0)
        let dad = self
        kid.dad = dad // Set the kid's three links.
        kid.kid = nil
        kid.sib = nil
        if dad.kid == nil {
            dad.kid = kid
        } else {
            kid.sib = dad.kid
            dad.kid = kid
        }
        return kid
    }

    /// Adds kid as a child of this node (self), after the given sib.
    /// If sib is nil, kid becomes the first child.
    /// Asserts if sib is not a child of self when non-nil.
    func addKidAfter(_ kid: GedcomNode, sib: GedcomNode?) {
        // Kid should not be attached.
        assert(kid.dad == nil && kid.sib == nil, "addKidAfter: cannot add a kid with links")

        let dad = self // Make dad a synonym for self (code is easier to understand).
        kid.dad = dad  // Set kid's dad.
        guard let sib = sib else {  // Handle sib == nil case.
            kid.sib = dad.kid  // dad.kid can be nil
            dad.kid = kid
            return
        }

        // Dad must have kids because sib in not nil.
        assert(dad.kid != nil, "addKidAfter: sib is not nil, but dad has no kids")

        // sib must be one of dad's kids.
        var found = false
        var cur = dad.kid
        while let node = cur {
            if node === sib {
                found = true
                break
            }
            cur = node.sib
        }
        assert(found, "addKidAfter: sib is not dad's child")
        kid.sib = sib.sib  // Insert kid after sib.
        sib.sib = kid
    }

    /// Find a node's last kid.
    func lastKid() -> GedcomNode? {
        var node = self.kid
        while let next = node?.sib {
            node = next
        }
        return node
    }

    /// Remove a kid from its parent.
    func removeKid() {
        guard let dad = dad else { return }

        if dad.kid === self {  // Remove first child.
            dad.kid = sib
        } else {  // Find prev sib of sib to remove.
            var prev = dad.kid
            while let s = prev?.sib, s !== self {
                prev = s
            }
            // Skip over self
            prev?.sib = sib
        }
        // Disconnect removed node.
        self.dad = nil
        self.sib = nil
    }

    /// Returns the previous sib of a node.
    var prevSib: GedcomNode? {

        guard let dad = self.dad, var curr = dad.kid, curr !== self else { return nil }
        while let next = curr.sib, next !== self {
            curr = next
        }
        return curr
    }

    /// Replace one child of this node with another.
    /// - Parameters:
    ///   - oldNode: The existing child to replace.
    ///   - newNode: The new child node (or subtree root).
    /// - Returns: `true` if replacement succeeded, `false` if `oldNode` wasn’t found.
    @discardableResult
    func replaceKid(old oldNode: GedcomNode, with newNode: GedcomNode) -> Bool {
        // Ensure new node is detached
        newNode.dad = self
        newNode.sib = oldNode.sib

        if kid === oldNode {
            // Case: old node was the first child
            kid = newNode
        } else {
            // Find the previous sibling
            var prev = kid
            while let s = prev?.sib, s !== oldNode {
                prev = s
            }
            guard prev?.sib === oldNode else { return false }
            prev?.sib = newNode
        }

        // Detach old node
        oldNode.dad = nil
        oldNode.sib = nil
        return true
    }

    /// Insert sib immediately after this node in the sibling chain.
    /// The sib node must not already be part of a sibling list or have a parent.
    ///
    /// After this call:
    /// - self.sib will point to sib
    /// - sib.dad will be set to self.dad
    /// - sib.sib will point to the old self.sib
    func addSib(_ sib: GedcomNode) {
        precondition(sib.sib == nil && sib.dad == nil, "Cannot add a node that is part of a tree")
        precondition(sib !== self, "Cannot add a node as a sibling to itself")

        sib.dad = self.dad
        sib.sib = self.sib
        self.sib = sib
    }

    /// Removes and returns the node's next sibling, if any. The sib is detached from
    /// the tree. This does not recursively remove the subtree under the sib.
    @discardableResult
    func removeSib() -> GedcomNode? {
        guard let sib = self.sib else { return nil }
        self.sib = sib.sib
        sib.dad = nil
        sib.sib = nil
        // Do not erase sib.kid; the caller may need to keep the subtree.
        return sib
    }

    /// Insert a child at a specific position (0 = front).
    func insertKid(_ newNode: GedcomNode, at index: Int) {
        guard index >= 0 else { return }
        if index == 0 {
            newNode.sib = kid
            newNode.dad = self
            kid = newNode
        } else {
            var prev = kid
            var count = 0
            while let current = prev, count < index - 1 {
                prev = current.sib
                count += 1
            }
            newNode.sib = prev?.sib
            newNode.dad = self
            prev?.sib = newNode
        }
    }

    /// Moves this node one position earlier in its dad's kid list.
    /// Does nothing if it's already the first child or has no parent.
    @discardableResult
    func moveUp() -> Bool {
        guard let dad = dad else { return false }
        guard let first = dad.kid, first !== self else { return false } // already first

        var prevPrev: GedcomNode? = nil
        var prev: GedcomNode? = first

        // Find node before the one pointing to self
        while let cur = prev?.sib, cur !== self {
            prevPrev = prev
            prev = cur
        }

        guard let prev = prev else { return false } // not found
        let me = prev.sib
        guard me === self else { return false }

        // Rewire
        prev.sib = me?.sib
        me?.sib = prev
        if let pp = prevPrev {
            pp.sib = me
        } else {
            dad.kid = me // self is now first
        }

        return true
    }

    /// Moves this node one position later in its parent's children list.
    /// Does nothing if it's already the last child or has no parent.
    /// Returns true if moved, false if it was already the last sibling.
    @discardableResult
    func moveDown() -> Bool {
        guard let parent = dad else { return false }
        guard let first = parent.kid else { return false }

        var prev: GedcomNode? = nil
        var current: GedcomNode? = first

        while let curr = current, let next = curr.sib {
            if curr === self {
                // Swap `curr` (self) and `next`
                curr.sib = next.sib
                next.sib = curr

                if let prev = prev {
                    prev.sib = next
                } else {
                    parent.kid = next
                }
                return true
            }

            prev = curr
            current = next
        }

        return false // self not found or already last
    }
}

extension GedcomNode {
    public func deepCopy() -> GedcomNode {
        let node = GedcomNode(key: self.key, tag: self.tag, val: self.val)
        node.kid = self.kid?.deepCopy() ?? nil
        node.sib = self.sib?.deepCopy() ?? nil
        return node
    }
}
