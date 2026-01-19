//
//  DragDropStuff.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 1 December 2025.
//  Last changed on 4 December 2025
//

import SwiftUI
import DeadEndsLib

/// Transferable drag and drop payload.
struct DragPayload: Transferable, Codable {

    /// Values that are serialized and transferred.
    var subtree: DraggedGedcomSubtree  // Structural clone
    var sourceTreeID: UUID             // Source tree.
    var sourceNodeUID: UUID            // Source node (when inside same tree).
    var sourceLevel: Int               // Gedcom level of dragged subtree root.

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }

    /// Create a transferable drag and drop payload.
    init(root: GedcomNode, treeID: UUID, nodeID: UUID, level: Int) {

        self.subtree = DraggedGedcomSubtree(node: root)
        self.sourceTreeID = treeID
        self.sourceNodeUID = nodeID
        self.sourceLevel = level
    }

    func toGedcomNode() -> GedcomNode {
        return subtree.toGedcomNode()
    }
}

/// Transferable wrapper for dragging a Gedcom subtree.
struct DraggedGedcomSubtree: Transferable, Codable {

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }

    /// The values that are serialized.
    var tag: String
    var val: String?
    var children: [DraggedGedcomSubtree]

    /// Creates a DraggedGedcomSubtree from a GedcomNode and its descendents, a transferrable
    /// representation of the node and its descendents.
    init(node: GedcomNode) {

        self.tag = node.tag
        self.val = node.val
        self.children = node.kids.map { DraggedGedcomSubtree(node: $0) }
        print("[DraggedGedcomSubtree.init] Created transferable representation:") // Debug.
        debugPrintSubtree(indent: "  ")  // Debug.
    }

    /// Creates a GedcomNode tree from a transferred version. The reverse operation of init.
    /// A method that takes a DraggedGedcomSubtree as its self argument.
    func toGedcomNode() -> GedcomNode {

        let newNode = GedcomNode(tag: tag, val: val)
        for child in children {
            newNode.addKid(child.toGedcomNode())
        }
        print("[DraggedGedcomSubtree.toGedcomNode] Reconstructed GedcomNode tree:") // Debug.
        newNode.debugPrintTree(prefix: "  ")  // Debug.

        return newNode
    }

    /// Debug method that prints a subtree.
    private func debugPrintSubtree(indent: String = "") {

        let valText = val ?? ""
        print("\(indent)\(tag) \(valText)")
        for child in children {
            child.debugPrintSubtree(indent: indent + "  ")
        }
    }
}

extension GedcomNode {

    func debugPrintTree(prefix: String = "") {
        self.printTree()
    }
}
