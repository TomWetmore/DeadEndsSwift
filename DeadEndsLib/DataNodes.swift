//
//  DataNodes.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 21 December 2024.
//  Last changed on 12 February 2026..
//

import Foundation

/// Struct that contains an array of pairs of Gedcom nodes and associated type.
struct DataNodes<Type> {
	var nodes: [(GedcomNode, Type)] // Representation.

    /// Create a data nodes object with empty array.
	init() { self.nodes = [] }

    /// Creates a DataNodes object from a [(GedcomNode, Type)] array.
    init(from tuples: [(GedcomNode, Type)]) { self.nodes = tuples }

	/// Add a (Gedcom node, type) pair to the array.
	mutating func add(node: GedcomNode, data: Type) { nodes.append((node, data)) }

	/// Return the associated value of a Gedcom node.
	func getInfo(for node: GedcomNode) -> Type? {
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

/// Implement sequence protocol.
extension DataNodes: Sequence {
    func makeIterator() -> IndexingIterator<Array<(GedcomNode, Type)>> {
        return nodes.makeIterator()
    }
}

/// Implement collection protocol.
extension DataNodes: Collection {
    typealias Index = Int
    typealias Element = (GedcomNode, Type)

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
