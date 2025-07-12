//
//  Traverse.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 8 January 2025.
//  Last changed on 12 July 2025.
//

import Foundation

// Traverse methods.
extension GedcomNode {

	// Void Closure (Default Behavior)
	func traverseChildren(_ action: (GedcomNode) -> Void) {
		var currentChild = self.child
		while let child = currentChild {
			action(child)
			currentChild = child.sibling
		}
	}

	// Boolean Closure (Early Exit)
	func traverseChildrenBool(_ action: (GedcomNode) -> Bool) {
		var currentChild = self.child
		while let child = currentChild {
			if action(child) { return } // Early exit
			currentChild = child.sibling
		}
	}

	// Accumulator Closure (Returns a Value)
	func traverseChildren<Result>(_ initial: Result, _ action: (GedcomNode, inout Result) -> Void) -> Result {
		var result = initial
		var currentChild = self.child
		while let child = currentChild {
			action(child, &result)
			currentChild = child.sibling
		}
		return result
	}

	// Filtering Closure (Conditional Traversal)
	func traverseChildren(where condition: (GedcomNode) -> Bool, _ action: (GedcomNode) -> Void) {
		var currentChild = self.child
		while let child = currentChild {
			if condition(child) {
				action(child)
			}
			currentChild = child.sibling
		}
	}

	// Generic Transform Closure (Map-Like Behavior)
	func mapChildren<Result>(_ transform: (GedcomNode) -> Result) -> [Result] {
		var results = [Result]()
		var currentChild = self.child
		while let child = currentChild {
			results.append(transform(child))
			currentChild = child.sibling
		}
		return results
	}

	// Reduce-Like Traversal
	func reduceChildren<Result>(_ initial: Result, _ nextPartialResult: (Result, GedcomNode) -> Result) -> Result {
		var result = initial
		var currentChild = self.child
		while let child = currentChild {
			result = nextPartialResult(result, child)
			currentChild = child.sibling
		}
		return result
	}
}

enum TreeTraversalOrder {
	case topDownLeftToRight
	case topDownRightToLeft
	case bottomUpLeftToRight
	case bottomUpRightToLeft

	var isTopDown: Bool {
		return self == .topDownLeftToRight || self == .topDownRightToLeft
	}

	var isBottomUp: Bool {
		return self == .bottomUpLeftToRight || self == .bottomUpRightToLeft
	}

	var isRightToLeft: Bool {
		return self == .topDownRightToLeft || self == .bottomUpRightToLeft
	}
}

extension GedcomNode {
	// Top-Down, Left-to-Right
	func traverseTopDownLeftToRight(_ action: (GedcomNode) -> Void) {
		action(self) // Process the current node first
		var child = self.child
		while let curchild = child {
			curchild.traverseTopDownLeftToRight(action) // Recursively traverse children
			child = curchild.sibling
		}
	}

	// Top-Down, Right-to-Left
	func traverseTopDownRightToLeft(_ action: (GedcomNode) -> Void) {
		action(self) // Process the current node first
		var children: [GedcomNode] = []
		var child = self.child
		while let curchild = child {
			children.append(curchild)
			child = curchild.sibling
		}
		for child in children.reversed() {
			child.traverseTopDownRightToLeft(action)
		}
	}

	// Bottom-Up, Left-to-Right
	func traverseBottomUpLeftToRight(_ action: (GedcomNode) -> Void) {
		var child = self.child
		while let curchild = child {
			curchild.traverseBottomUpLeftToRight(action) // Recursively traverse children
			child = curchild.sibling
		}
		action(self) // Process the current node last
	}

	// Bottom-Up, Right-to-Left
	func traverseBottomUpRightToLeft(_ action: (GedcomNode) -> Void) {
		var children: [GedcomNode] = []
		var child = self.child
		while let curchild = child {
			children.append(curchild)
			child = curchild.sibling
		}
		for child in children.reversed() {
			child.traverseBottomUpRightToLeft(action)
		}
		action(self) // Process the current node last
	}

	// General Unified Traversal
	func traverseTree(order: TreeTraversalOrder, action: (GedcomNode) -> Void) {
		let children = collectChildren(order: order)

		if order.isTopDown {
			action(self)
		}
		for child in children {
			child.traverseTree(order: order, action: action)
		}
		if order.isBottomUp {
			action(self)
		}
	}

	private func collectChildren(order: TreeTraversalOrder) -> [GedcomNode] {
		var children: [GedcomNode] = []
		var child = self.child
		while let curchild = child {
			children.append(curchild)
			child = curchild.sibling
		}
		if order.isRightToLeft {
			children.reverse()
		}
		return children
	}
}

extension GedcomNode {
	// Function to print a Node tree in an indented Gedcom-like format
	func printIndentedGedcomTree() {
		self.topDown { node, level in
			let indentation = String(repeating: "  ", count: level) // 2 spaces per level
			let key = node.key.map { "@\($0)@" } ?? "" // Wrap the key in @...@ if present
			let tag = node.tag
			let value = node.value ?? ""
			print("\(indentation)\(level) \(key) \(tag) \(value)".trimmingCharacters(in: .whitespaces))
		}
	}

	// Top-down traversal with level tracking
	func topDown(_ action: (GedcomNode, Int) -> Void, level: Int = 0) {
		action(self, level)
		var child = self.child
		while let currentChild = child {
			currentChild.topDown(action, level: level + 1)
			child = currentChild.sibling
		}
	}
}

// Making Nodes conform to Sequence for top-down, left-right sequencing.
extension GedcomNode: Sequence {
	public struct NodeIterator: IteratorProtocol {
		var stack: [GedcomNode]

		init(root: GedcomNode) {
			self.stack = [root]
		}
		
		public mutating func next() -> GedcomNode? {
			guard !stack.isEmpty else { return nil }
			let node = stack.removeFirst()
			var child = node.child
			while let curchild = child {
				stack.append(curchild)
				child = curchild.sibling
			}
			return node
		}
	}
	
	public func makeIterator() -> NodeIterator {
		return NodeIterator(root: self)
	}
}
