//
//  GedcomNode.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 18 Devember 2024.
//  Last changed on 26 September 2026.
//

import Foundation

public typealias Root = GedcomNode
public typealias Tag = String

/// A GedcomNode holds a single Gedcom line. The key, tag and val are from the Gedcom line;
/// lev is computed. The sib, kid and dad fields hold the tree structure. Each node has a
/// UUID, required by the user interface. The unfortunate names sib, kid and dad were chosen
/// to avoid conflict with the inter-record terms sibling, child and parent. GedcomNode is
/// a class so has reference semantics.

final public class GedcomNode: Identifiable, CustomStringConvertible {

    public let id = UUID()           // Unique identifier of the node.

    public var key: RecordKey?       // Record key required on level 0 nodes.

    public var tag: Tag              // Gedcom tag required on all nodes.

    public var val: String?          // Gedcom value required on some nodes.

    public var sib: GedcomNode?      // Next sibling in Gedcom tree.

    public var kid: GedcomNode?      // First child in Gedcom tree.

    public weak var dad: GedcomNode? // Parent node in tree, required on non-roots.

    /// Return the kids of a GedcomNode as an array of nodes. They are not copied and their
    /// structural properties are not affected.

    public var kids: [GedcomNode] {

        var results: [GedcomNode] = []
        var node = kid
        while let current = node {
            results.append(current)
            node = current.sib
        }
        return results
    }

    /// Return the sibs of a GedcomNode as an array of nodes. They are not copied and their
    /// structural properties are not affected.

    public var sibs: [GedcomNode] {
        var results: [GedcomNode] = []
        var node = sib
        while let current = node {
            results.append(current)
            node = current.sib
        }
        return results
    }

    /// Return a description of a single GedcomNode.

    public var description: String {

        var description = "\(lev) "
        if let key { description += "\(key) " }
        description += "\(tag)"
        if let val { description += " \(val) " }
        return description
    }

    /// Create an unlinked Gedcom node.

    public init(key: RecordKey? = nil, tag: Tag, val: String? = nil) {

        self.key = key
        self.tag = tag
        self.val = val
    }

    /// Return the level of a GedcomNode by counting steps to the root; cycles are detected.

    public var lev: Int {

        var level = 0
        var node: GedcomNode? = self
        while let current = node, level < 100 {
            level += 1
            node = current.dad
        }
        return level
    }

    /// Print a GedcomNode tree to stdout; recurse to kids and sibs.

    public func printTree(level: Int = 0, indent: String = "") {

        if level < 0 || level > 100 {
            return
        }
        let space = String(repeating: indent, count: level)
        print("\(space)\(level) \(self)")
        
        kid?.printTree(level: level + 1, indent: indent)
        sib?.printTree(level: level, indent: indent)
    }
}

/// Methods that return kid nodes or their values.

public extension GedcomNode {

    /// Return the first kid with the given tag.

    func kid(withTag tag: Tag) -> GedcomNode? {

        var node = kid
        while let current = node {
            if current.tag == tag {
                return current
            }
            node = current.sib
        }
        return nil
    }

    /// Return the first kid with a tag from a list of tags.

    func kid(withTags tags: [Tag]) -> GedcomNode? {

        let tagSet = Set(tags)
        var node = kid
        while let current = node {
            if tagSet.contains(current.tag) {
                return current
            }
            node = current.sib
        }
        return nil
    }

    /// Return all kids with the given tag.

    func kids(withTag tag: Tag) -> [GedcomNode] {

        var results: [GedcomNode] = []
        var node = kid
        while let curr = node {
            if curr.tag == tag {
                results.append(curr)
            }
            node = curr.sib
        }
        return results
    }

    /// Return all kids with tags from a tag list.

    func kids(withTags tags: [Tag]) -> [GedcomNode] {

        let tagSet = Set(tags)
        var results: [GedcomNode] = []
        var node = kid
        while let curr = node {
            if tagSet.contains(curr.tag) {
                results.append(curr)
            }
            node = curr.sib
        }
        return results
    }

    /// Return the val of first kid with a given tag.

    func kidVal(forTag tag: Tag) -> String? {

        return kid(withTag: tag)?.val
    }

    /// Return the val of first kid with a tag from a list of tags.

    func kidVal(forTags tags: [Tag]) -> String? {

        return kid(withTags: tags)?.val
    }

    /// Return the list of all non-nil vals from .self's kids with the given tag.

    func kidVals(forTag tag: Tag) -> [String] {

        kids(withTag: tag).compactMap { $0.val }
    }

    /// Return the list of all non-nil vals from .self's kids with tags in the given list of tags.

    func kidVals(forTags tags: [Tag]) -> [String] {

        kids(withTags: tags).compactMap { $0.val }
    }

    /// Traverse first sequence of specific tags to descendant node.

    func kid(atPath path: [Tag]) -> GedcomNode? {

        guard !path.isEmpty else {
            return nil
        }
        return path.reduce(into: Optional(self)) { node, tag in
            node = node?.kid(withTag: tag)
        }
    }

    /// Traverse first sequence of specific tags to descendant node's value.

    func kidVal(atPath path: [Tag]) -> String? {

        path.reduce(self) { node, tag in node?.kid(withTag: tag) }?.val
    }
}

public extension GedcomNode {

    /// Convert a GedcomNode tree to Gedcom text.

    func gedcomText(level: Int = 0, indent: Bool = false) -> String {
        
        var lines: [String] = []

        let space = indent ? String(repeating: "  ", count: level) : ""
        var line = space + "\(level)"
        if level == 0, let k = self.key {
            line += " \(k)"
        }
        line += " \(self.tag)"
        if let value = self.val, !value.isEmpty {
            line += " \(value)"
        }
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

    /// Return the number of nodes rooted at this node.

    public var count: Int {

        var count = 1
        var child = self.kid
        while let curchild = child {
            count += curchild.count
            child = curchild.sib
        }
        return count
    }

    /// Return the number of nodes before this node in its tree.

    public var index: Int {

        var count = 0
        var curNode: GedcomNode? = self
        var loops = 0
        while let node = curNode, let dad = node.dad {
            loops += 1
            if loops > 100 { fatalError("Cycle detected in tree by the index method.") }
            var sibling = dad.kid // Count previous sibs.
            while let cursibling = sibling, cursibling !== node {
                count += cursibling.count
                sibling = cursibling.sib
            }
            curNode = dad
            count += 1  // Include parent.
        }
        return count
    }
}

extension GedcomNode {

    /// Return all GedcomNodes below a node. This returns an array of references to the
    /// GedcomNodes that are in the tree; they are not copies and their structural links
    /// are not affected.

    public var subnodes: [GedcomNode] {

        var result: [GedcomNode] = []
        visit(self.kid)
        return result

        func visit(_ node: GedcomNode?) {
            guard let node = node else { return }
            result.append(node)
            visit(node.kid)
            visit(node.sib)
        }
    }
}

public extension GedcomNode {

    /// Return whether a GedcomNode has kids.

    var hasKids: Bool {
        
        self.kid != nil
    }

    /// Create and add a new first kid to this GedcomNode.

    @discardableResult
    func addKid(tag: String, val: String? = nil) -> GedcomNode {

        let child = GedcomNode(tag: tag, val: val)
        return addKid(child)
    }

    /// Add a GedcomNode as self GedcomNode's new first kid.

    @discardableResult
    func addKid(_ kid: GedcomNode) -> GedcomNode {

        kid.requireDisconnected()
        let dad = self  // Makes code easier to read.

        kid.dad = dad
        kid.sib = dad.kid
        dad.kid = kid

        return kid
    }

    /// Add kid as a new kid of .self, after the given sib.
    /// If sib is nil, kid becomes the first kid.
    /// Asserts if sib is not a kid of .self when non-nil.

    func oldaddKidAfter(_ kid: GedcomNode, sib: GedcomNode?) {

        // Kid should not be attached.
        assert(kid.dad == nil && kid.sib == nil, "addKidAfter: cannot add a kid with links")

        let dad = self // Make dad a synonym of self.
        kid.dad = dad  // Set kid's dad.
        guard let sib else {  // Handle sib == nil case.
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

    /// Return the last kid of a GedcomNode.

    func lastKid() -> GedcomNode? {

        var node = self.kid
        while let next = node?.sib {
            node = next
        }
        return node
    }

    func addKidAfter(_ kid: GedcomNode, sib: GedcomNode?) {

        precondition(kid.dad == nil && kid.sib == nil,
                     "addKidAfter: kid is already attached")

        if let sib {
            precondition(sib.dad === self,
                         "addKidAfter: sib is not a child of self")

            kid.dad = self
            kid.sib = sib.sib
            sib.sib = kid
        } else {
            kid.dad = self
            kid.sib = self.kid
            self.kid = kid
        }
    }

    /// Remove a kid from its parent.
    /// TODO: Should return the removed kid.

    @discardableResult
    func removeKid() -> GedcomNode? {

        guard let dad else { return nil }

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
        return nil
    }

    /// Return the previous sib of a GedcomNode.

    var prevSib: GedcomNode? {

        guard let dad, var curr = dad.kid, curr !== self else {
            return nil
        }
        while let next = curr.sib {
            if next === self {
                return curr
            }
            curr = next
        }
        return nil
    }

    /// Insert a forest (one node or a sib chain) into this node's kid list.
    /// - Parameters:
    ///   - first: first root of the forest to insert (may be a single node).
    ///   - after: existing child after which to insert; if nil, inserts at front.
    ///
    /// Preconditions:
    /// - every root in the inserted forest has dad == nil
    /// - if after != nil, then after.dad === self
    func insertKidForest(_ first: GedcomNode, after: GedcomNode? = nil) {

        if let after {
            precondition(after.dad === self, "insertKidForest: 'after' is not a child of this node")
        }

        // Walk the forest: set each root's dad, and find the last root.
        var last: GedcomNode = first
        var cur: GedcomNode? = first
        while let node = cur {
            precondition(node.dad == nil, "insertKidForest: cannot insert a node that already has a parent")
            node.dad = self
            last = node
            cur = node.sib
        }

        // Splice the forest into the kid list.
        if let after {
            last.sib = after.sib
            after.sib = first
        } else {
            last.sib = self.kid
            self.kid = first
        }
    }


    /// Replace this GedcomNode with a disconnected GedcomNode.
    /// Return this node, disconnected from its original tree.

    @discardableResult
    func replace(_ new: GedcomNode) -> GedcomNode {

        new.requireDisconnected()
        new.dad = self.dad
        new.sib = self.sib

        if let prev = self.prevSib {
            prev.sib = new
        } else {
            self.dad?.kid = new
        }
        self.dad = nil
        self.sib = nil
        return self
    }

    @discardableResult
    func replace(old oldNode: GedcomNode, with newNode: GedcomNode) -> Bool {
        if newNode.sib != nil { fatalError("new node cannot be a forest") }
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

    /// Add a GedcomNode, and any descendants, after this GedcomNode in the dad's
    /// sibling chain. The sib node must be detached.

    func addSib(_ sib: GedcomNode) {

        sib.requireDisconnected()

        sib.dad = self.dad
        sib.sib = self.sib
        self.sib = sib
    }

    /// Remove and return self's next sibling, including its descendants.
    /// The returned node is disconnected.

    @discardableResult
    func removeSib() -> GedcomNode? {

        guard let sib = self.sib else {
            return nil  // No next sibling.
        }
        self.sib = sib.sib
        sib.dad = nil
        sib.sib = nil
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

    /// Move this GedcomNode one position earlier in its dad's kid list; does nothing
    /// if it is already the first child or has no parent.

    @discardableResult
    func moveUp() -> Bool {

        guard let dad else {
            return false
        }
        guard let first = dad.kid, first !== self else {
            return false
        }

        var prevPrev: GedcomNode?
        var prev: GedcomNode? = first

        while let cur = prev?.sib, cur !== self {
            prevPrev = prev
            prev = cur
        }
        guard let prev, prev.sib === self else {
            return false
        }

        // Swap self with its previous sibling.
        prev.sib = self.sib
        self.sib = prev

        if let prevPrev {
            prevPrev.sib = self
        } else {
            dad.kid = self
        }
        return true
    }

    /// Move this GedcomNode one position down in its dad's kid list. Return
    /// false if the node has no dad or is already the last kid.

    @discardableResult
    func moveDown() -> Bool {

        guard let dad, let next = sib else {
            return false  // Must have dad and sib to continue.
        }

        let prev = prevSib

        self.sib = next.sib
        next.sib = self

        if let prev {
            prev.sib = next
        } else {
            dad.kid = next
        }
        return true
    }
}


extension GedcomNode {

    /// Require a GedcomNode to have a key and optionally a tag. Must succeed.

    func requireKey(tag: Tag? = nil) -> RecordKey {

        DeadEndsLib.requireKey(on: self, tag: tag)
    }

    var requireKey: RecordKey {

        DeadEndsLib.requireKey(on: self)
    }

    // Require a GedcomNode val to hold a link key.

    var requireLink: RecordKey {

        guard let val, val.isKey else {
            fatalError("GedcomNode does not contain a valid link")
        }
        return val
    }
}

/// Require a root node to have a key. Must succeed.

func requireKey(on root: GedcomNode, tag: Tag? = nil) -> RecordKey {

    guard let key = root.key else {
        fatalError("expected root \(root) to have a key")
    }
    if tag == nil {
        return key
    }
    guard tag! == root.tag else {
        fatalError("expected root \(root) to have key \(tag!)")
    }
    return key
}

extension GedcomNode {

    /// Require that a GedcomNode do not have a dad or a sib link.

    func requireDisconnected() {

        guard dad == nil, sib == nil else {
            fatalError("GedcomNode \"\(self)\" must be disconnected")
        }
    }
}

extension GedcomNode {

    /// Create and return a deep copy of a GedcomNode and the full tree below it.

    public func deepCopy(dad: GedcomNode? = nil, sibs: Bool = true) -> GedcomNode {

        let copy = GedcomNode(key: key, tag: tag, val: val)
        copy.dad = dad

        if let kid {
            copy.kid = kid.deepCopy(dad: copy)
        }
        if sibs, let sib {
            copy.sib = sib.deepCopy(dad: dad)
        }
        return copy
    }

    /// Cleanly remove a GedcomNode (and those below it) from anywhere in a GedcomNode tree.

    func remove() {

        if let prev = prevSib {
            prev.sib = sib
        } else {
            dad?.kid = sib
        }
    }
}
