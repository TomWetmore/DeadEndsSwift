//
//  DataNodes.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 21 December 2024.
//  Last changed on 15 October 2026.
//

import Foundation

/// Struct of an array of root GedcomNodes with an associated type. Used by the import stack
/// to hold the GedcomNode levels when GedcomSources are read.
///
struct DataNodes<Type> {
    
	var nodes: [(Root, Type)] // Representation.

    /// Create a DataNodes object with an empty array.
    ///
	init() {

        self.nodes = []
    }

    /// Create a DataNodes object from a tuple array.
    ///
    init(from tuples: [(Root, Type)]) {

        self.nodes = tuples
    }

	/// Append a tuple to this DataNodes object.
    ///
	mutating func add(node: Root, data: Type) {

        nodes.append((node, data))
    }

	/// Return the associated value of DataNode element.
    ///
	func getInfo(for node: Root) -> Type? {

		return nodes.first { $0.0 === node }?.1
	}

    /// Return the array of all GedcomNodes.
    ///
	func allNodes() -> [GedcomNode] {

		return nodes.map { $0.0 }
	}

    /// Return the array of all associated values. Probably not useful.
    ///
	func allInfo() -> [Type] {

		return nodes.map { $0.1 }
	}
}

/// Implement Sequence.
///
extension DataNodes: Sequence {

    func makeIterator() -> IndexingIterator<Array<(GedcomNode, Type)>> {
        return nodes.makeIterator()
    }
}

/// Implement Collection.
///
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
