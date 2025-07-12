//
//  GedcomNode.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 18 Devember 2024.
//  Last changed on 12 July 2025.
//

import Foundation

// TagMap is [String:String] map that ensures only one copy of each tag in a database.
class TagMap {

	private var map: [String:String] = [:]

	func intern(tag: String) -> String {
		if let existing = map[tag] { return existing }
		map[tag] = tag
		return tag
	}
}

// GNodeNode is the class of Gedcom nodes. Each GNodeNode represents one line in a Gedcom file. key, tag and
// value are the key (cross reference identifier), tag, and value of the Gedcom line. The line's level number
// is inferred when needed.
public class GedcomNode: CustomStringConvertible {

	public var key: String? // Key; only on root nodes.
	public var tag: String  // Gedcom tag; mandatory.
	public var value: String? // Value; optional.
	public var sibling: GedcomNode? // Next sibling; optional.
	public var child: GedcomNode?  // First child; optional.
	public weak var parent: GedcomNode? // Parent; not on root nodes.

	public var description: String {
		var description =  ""
		if let key { description += "\(key) " }
		description += "\(tag)"
		if let value { description += " \(value) " }
		return description
	}

	// init initializes a new GedcomNode with key, tag and value.
	init(key: String? = nil, tag: String, value: String? = nil) {
		self.key = key
		self.tag = tag
		self.value = value
	}

	// Print a GedcomNode tree for debugging.
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

    // Returns the value of the first child with the given tag, if any.
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

    // Returns the first child node with the given tag, if any.
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

    // Return all children with the given tag.
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

