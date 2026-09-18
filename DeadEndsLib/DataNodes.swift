//
//  DataNodes.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 21 December 2024.
//  Last changed on 18 September 2026.
//

import Foundation

/// Struct of an array of Gedcom nodes with an associated type. Currently used by the
/// import stack to hold Gedcom node levels when Gedcom files are read.
struct DataNodes<Type> {
    
	var nodes: [(Root, Type)] // Representation.

    /// Create a data nodes object with an empty array.
	init() {

        self.nodes = []
    }

    /// Create a data nodes object from a tuple array.
    init(from tuples: [(Root, Type)]) {

        self.nodes = tuples
    }

	/// Append a tuple to this data nodes object.
	mutating func add(node: Root, data: Type) {

        nodes.append((node, data))
    }

	/// Return the associated value of a node.
	func getInfo(for node: Root) -> Type? {

		return nodes.first { $0.0 === node }?.1
	}

    /// Return the array of all Gedcom nodes.
	func allNodes() -> [GedcomNode] {

		return nodes.map { $0.0 }
	}

    /// Return the array of all associated values.
	func allInfo() -> [Type] {
        
		return nodes.map { $0.1 }
	}
}

/// Implement sequence.
extension DataNodes: Sequence {

    func makeIterator() -> IndexingIterator<Array<(GedcomNode, Type)>> {
        return nodes.makeIterator()
    }
}

/// Implement collection.
extension DataNodes: Collection {

    typealias Index = Int
    typealias Element = (Root, Type)

    var startIndex: Index { nodes.startIndex }
    var endIndex: Index { nodes.endIndex }

    func index(after i: Index) -> Index {
        nodes.index(after: i)
    }

    subscript(position: Index) -> Element {
        nodes[position]
    }
}

extension DataNodes {
    
	mutating func sort(by areInIncreasingOrder: (Type, Type) -> Bool) {
		nodes.sort { areInIncreasingOrder($0.1, $1.1) }
	}
}
