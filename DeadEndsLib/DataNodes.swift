//
//  DataNodes.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 21 December 2024.
//  Last changed on 26 April 2025.
//

import Foundation

// DataNodes is a struct that contains an Array of pairs of GedcomNodes with an associated type.
struct DataNodes<Type> {
	var nodes: [(GedcomNode, Type)] // Array of tuples making up the List.

    // init creates a DataNodes object with an empty array.
	init() { self.nodes = [] }

    // init creates a DataNodes object from a [(GedcomNode, Type)] array.
    init(from tuples: [(GedcomNode, Type)]) { self.nodes = tuples }

	// add adds a (GedcomNode, Type) pair to the array.
	mutating func add(node: GedcomNode, data: Type) { nodes.append((node, data)) }

	// getInfo returns the associated value of a GedcomNode.
	func getInfo(for node: GedcomNode) -> Type? {
		return nodes.first { $0.0 === node }?.1
	}

    // allNodes returns the array of all GedcomNodes.
	func allNodes() -> [GedcomNode] {
		return nodes.map { $0.0 }
	}

    // allInfo returns the array of all associated values.
	func allInfo() -> [Type] {
		return nodes.map { $0.1 }
	}
}

// DataNodes extension to implement the Sequence protocol.
extension DataNodes: Sequence {
    func makeIterator() -> IndexingIterator<Array<(GedcomNode, Type)>> {
        return nodes.makeIterator()
    }
}

// DataNodes extension to implement the Collection protocol.
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
