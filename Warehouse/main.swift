//
//  main.swift
//  TraverseSequence
//
//  Created by Thomas Wetmore on 2/22/25.
//  Last changed on 24 February 2025.
//

import Foundation

// MARK: TreeNode Protocol
protocol TreeNode: Sequence {
	associatedtype NodeType: TreeNode = Self

	var parent: NodeType? { get }
	var firstChild: NodeType? { get }
	var nextSibling: NodeType? { get }

	func traversePreorder(_ action: (NodeType) -> Void)
}

// MARK: Preorder Traversal Implementation
extension TreeNode {
	func traversePreorder(_ action: (NodeType) -> Void) {
		action(self as! NodeType)  // Required because Self and NodeType aren't always the same
		var child = self.firstChild
		while let curchild = child as? Self {  // Explicit type conversion
			curchild.traversePreorder(action)  // Now properly typed
			child = curchild.nextSibling
		}
	}
}

// MARK: Node Class
/*final*/ class Node: TreeNode {
	var parent: Node?
	var firstChild: Node?
	var nextSibling: Node?

	let value: String  // Example payload.

	init(value: String) {
		self.value = value
	}

	// MARK: Implement Sequence Conformance
	// PreorderIterator defines Sequence Iterators for objects that implement the TreeNode protocol.
	struct PreorderIterator: IteratorProtocol {
		private var queue: ArraySlice<Node> // Using a slice makes .dropFirst O(1).

		// init initializes this iterator.
		init(root: Node) {
			self.queue = [root]
		}

		// next returns the next Node in pre-order sequence.
		mutating func next() -> Node? {
			guard let current = queue.first else { return nil }
			queue = queue.dropFirst() // O(1).
			var child = current.firstChild
			while let curchild = child {
				queue.append(curchild)
				child = curchild.nextSibling
			}
			return current
		}
	}

	// makeIterator makes a pre-order iterator.
	func makeIterator() -> PreorderIterator {
		return PreorderIterator(root: self)
	}
}

// MARK: - Example Usage
let root = Node(value: "Root")
let child1 = Node(value: "Child 1")
let child2 = Node(value: "Child 2")
let child3 = Node(value: "Child 3")
let subchild1 = Node(value: "Subchild 1")
let subchild2 = Node(value: "Subchild 2")

// Construct test tree.
root.firstChild = child1
child1.nextSibling = child2
child2.nextSibling = child3
child1.firstChild = subchild1
subchild1.nextSibling = subchild2

// Test Iteration
print("Preorder Traversal Using Sequence Conformance:")
for node in root {
	print(node.value)
}
