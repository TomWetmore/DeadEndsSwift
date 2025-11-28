//
//  GedcomTreeEditorModel.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 2 October 2025.
//  Last changed on 27 November 2025.
//

import SwiftUI
import DeadEndsLib

/// Model for a GedcomTreeEditor; tracks the selected and expanded nodes.
@MainActor
@Observable
final class GedcomTreeEditorModel {

    var expandedSet: Set<UUID> = []  // Set of all nodes that are expanded in the view.
    var selectedNode: GedcomNode? = nil  // The selected node in the view.
    var rowFrames: [UUID: CGRect] = [:]  // The frames of the visible GedcomTreeEditorRows.

    /// Convenience initializer; a root node is selected and expanded.
    /// expanded.
    init(root: GedcomNode? = nil) {
        self.selectedNode = root
        if let root = root { expandedSet.insert(root.uid) }
    }

    /// Toggles the expanded state of a node and makes it the selected node.
    func toggleExpansion(for node: GedcomNode) {
        if expandedSet.contains(node.uid) {
            expandedSet.remove(node.uid)
        } else {
            expandedSet.insert(node.uid)
        }
        selectedNode = node
    }


    var canDeleteSelectedNode: Bool {
        guard let node = selectedNode else { return false }
        if node.lev == 0 { return false }
        if node.lev == 1 && GedcomTreeManager.lineageLinkedTags.contains(node.tag) { return false }
        return true
    }

    /// Checks if the selected node can be moved after its next sibling.
    var canMoveDownSelectedNode: Bool {
        guard let node = selectedNode else { return false }
        return node.sib != nil
    }

    /// Checks if the selected node can be moved before its previous sibling.
    var canMoveUpSelectedNode: Bool {
        guard let node = selectedNode else { return false }
        return node.prevSib != nil
    }

    /// Selects the dad of the selected node.
    func selectDad() {
        guard let node = selectedNode,
              let parent = node.dad else { return }
        selectedNode = parent
    }

    /// Selects the first kid of the selected node.
    func selectFirstKid() {
        guard let dad = selectedNode, let kid = dad.kid else { return }
        // Be sure dad is expanded so kid is visible.
        expandedSet.insert(dad.uid)
        selectedNode = kid
    }

    /// Selects the next sib of the selected node.
    func selectNextSib() {
        guard let node = selectedNode,
              let next = node.sib else { return }
        selectedNode = next
    }

    /// Selects the previous sib of the selected node.
    func selectPrevSib() {
        guard let node = selectedNode else { return }
        guard let parent = node.dad,
              var current = parent.kid,
              current !== node else { return }

        while let next = current.sib, next !== node {
            current = next
        }
        selectedNode = current
    }
}
