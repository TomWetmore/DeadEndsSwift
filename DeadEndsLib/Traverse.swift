//
//  Traverse.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 8 January 2025.
//  Last changed on 26 September 2026.
//

import Foundation

// Traverse methods.
extension GedcomNode {

	// Void Closure (Default Behavior)
	func traverseChildren(_ action: (GedcomNode) -> Void) {
		var currentChild = self.kid
		while let child = currentChild {
			action(child)
			currentChild = child.sib
		}
	}
}

// Making Nodes conform to Sequence for top-down, left-right sequencing.
//extension GedcomNode: Sequence {
//	public struct NodeIterator: IteratorProtocol {
//		var stack: [GedcomNode]
//
//		init(root: GedcomNode) {
//			self.stack = [root]
//		}
//		
//		public mutating func next() -> GedcomNode? {
//			guard !stack.isEmpty else { return nil }
//			let node = stack.removeFirst()
//			var child = node.kid
//			while let curchild = child {
//				stack.append(curchild)
//				child = curchild.sib
//			}
//			return node
//		}
//	}
//	
//	public func makeIterator() -> NodeIterator {
//		return NodeIterator(root: self)
//	}
//}
