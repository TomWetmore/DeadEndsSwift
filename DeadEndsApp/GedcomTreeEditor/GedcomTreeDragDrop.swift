//
//  GedcomTreeDragDrop.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 1 December 2025.
//  Last changed on 4 March 2026.
//

import SwiftUI
import DeadEndsLib

/// Transferable drag and drop payload.
struct DragPayload: Transferable, Codable {

    /// Serialized values.
    var subtree: TransferGedcomTree  // Structural clone
    var sourceTreeID: UUID             // Source tree.
    var sourceNodeUID: UUID            // Source node (when inside same tree).
    var sourceLevel: Int               // Level of dragged subtree root.

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }

    /// Create drag and drop payload.
    init(root: GedcomNode, treeID: UUID, nodeID: UUID, level: Int) {
        self.subtree = TransferGedcomTree(node: root)
        self.sourceTreeID = treeID
        self.sourceNodeUID = nodeID
        self.sourceLevel = level
    }

    func toGedcomNode() -> GedcomNode {
        return subtree.toGedcomNode()
    }
}

/// Wrapper for dragging a Gedcom tree.
struct TransferGedcomTree: Transferable, Codable {

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }

    /// Serialized values.
    var tag: String
    var val: String?
    var children: [TransferGedcomTree]

    /// Create transfer Gedcom tree from Gedcom node and its descendents.
    init(node: GedcomNode) {
        self.tag = node.tag
        self.val = node.val
        self.children = node.kids.map { TransferGedcomTree(node: $0) }
        print("[TransferGedcomTree.init] Created transferable representation:") // Debug.
        debugPrintSubtree(indent: "  ")  // Debug.
    }

    /// Create Gedcom node tree from a transfer version; reverse operation of init.
    func toGedcomNode() -> GedcomNode {
        let newNode = GedcomNode(tag: tag, val: val)
        for child in children {
            newNode.addKid(child.toGedcomNode())
        }
        print("[TransferGedcomTree.toGedcomNode] Reconstructed GedcomNode tree:") // Debug.
        newNode.debugPrintTree(prefix: "  ")  // Debug.
        return newNode
    }

    /// Debug method to print a transfer subtree.
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
