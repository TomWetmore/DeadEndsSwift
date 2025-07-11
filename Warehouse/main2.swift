//
//  main.swift
//  TraversalTest
//
//  Created by Thomas Wetmore on 2/22/25.
//

import Foundation

// MARK: - Protocol for Tree Nodes
protocol TreeNode {
	//associatedtype NodeType = Self // where NodeType == Self  // Ensure NodeType is always Self
	associatedtype NodeType = Self where NodeType == Self  // Ensure NodeType is always Self
	var parent: NodeType? { get }
	var firstChild: NodeType? { get }
	var nextSibling: NodeType? { get }
}

// MARK: Gedcom Node Example.
final class Node: TreeNode { // final is required to compile.
	var key: String?       // Gedcom key (on root Nodes).
	var tag: String        // Gedcom tag (on all Nodes).
	var value: String?     // Gedcom value field (optional on many Nodes).
	var parent: Node?      // Parent Node (only nil in root Nodes); part of TreeNode Protocol.
	var firstChild: Node?  // First child; part of TreeNode Protocol.
	var nextSibling: Node? // Next sibling; part of TreeNode Protocol.

	init(key: String? = nil, tag: String, value: String? = nil) {
		self.key = key
		self.tag = tag
		self.value = value
	}

	// Adds a child to this node (maintains first-child/next-sibling structure)
	func addChild(_ child: Node) {
		child.parent = self
		if firstChild == nil {
			firstChild = child
		} else {
			var last = firstChild
			while let sibling = last?.nextSibling {
				last = sibling
			}
			last?.nextSibling = child
		}
	}
}

// MARK: - Traversal Extensions
extension TreeNode {

	// **Preorder Traversal (Top-Down, Left-to-Right)**
	func traversePreorder(_ action: (Self) -> Void) {
		action(self)
		var child = firstChild
		while let node = child {
			node.traversePreorder(action)
			child = node.nextSibling
		}
	}

	// **Postorder Traversal (Bottom-Up, Left-to-Right)**
	func traversePostorder(_ action: (Self) -> Void) {
		var child = firstChild
		while let node = child {
			node.traversePostorder(action)
			child = node.nextSibling
		}
		action(self)
	}

	// **Breadth-First Traversal (Level Order)**
	func traverseBreadthFirst(_ action: (Self) -> Void) {
		var queue: [Self] = [self]
		while !queue.isEmpty {
			let node = queue.removeFirst()
			action(node)
			var child = node.firstChild
			while let c = child {
				queue.append(c)
				child = c.nextSibling
			}
		}
	}

	// **Traversal with KeyPath (Extract Specific Properties)**
	func traverse<KeyType>(
		keyPath: KeyPath<Self, KeyType>,
		action: (KeyType) -> Void
	) {
		action(self[keyPath: keyPath])
		var child = firstChild
		while let node = child {
			node.traverse(keyPath: keyPath, action: action)
			child = node.nextSibling
		}
	}
}

// MARK: - Example Usage
func testTreeTraversal() {
	let root = Node(tag: "ROOT")
	let child1 = Node(tag: "A")
	let child2 = Node(tag: "B")
	let child3 = Node(tag: "C")
	let subChild1 = Node(tag: "X")
	let subChild2 = Node(tag: "Y")

	root.addChild(child1)
	root.addChild(child2)
	root.addChild(child3)
	child1.addChild(subChild1)
	child2.addChild(subChild2)

	print("Preorder Traversal:")
	root.traversePreorder { print($0.tag) }

	print("\nPostorder Traversal:")
	root.traversePostorder { print($0.tag) }

	print("\nBreadth-First Traversal:")
	root.traverseBreadthFirst { print($0.tag) }

	print("\nExtracting Tags with KeyPath Traversal:")
	root.traverse(keyPath: \.tag) { print($0) }
}

// Run the test function
testTreeTraversal()
