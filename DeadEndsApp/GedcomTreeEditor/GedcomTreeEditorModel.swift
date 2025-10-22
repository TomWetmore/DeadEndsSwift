//
//  GedcomTreeEditorModel.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 2 October 2025.
//  Last changed on 17 October 2025.
//

import SwiftUI
import DeadEndsLib

/// Model for a GedcomTreeEditor; tracks the selected and expanded nodes.
@MainActor
final class GedcomTreeEditorModel: ObservableObject {

    @Published var expandedSet: Set<UUID> = []  // Set of all nodes that are expanded in the full view.
    @Published var selectedNode: GedcomNode? = nil  // The selected node in the full view.

    /// Toggles the expanded state of a node and makes it the selected node.
    func toggleExpansion(for node: GedcomNode) {
        if expandedSet.contains(node.id) {
            expandedSet.remove(node.id)
        } else {
            expandedSet.insert(node.id)
        }
        selectedNode = node
    }


    var canDeleteSelectedNode: Bool {
        guard let node = selectedNode else { return false }
        if node.lev == 0 { return false }
        if node.lev == 1 && GedcomTreeManager.lineageLinkedTags.contains(node.tag) { return false }
        return true
    }

    var canMoveDownSelectedNode: Bool {
        guard let node = selectedNode else { return false }
        return node.sib != nil
    }

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
        expandedSet.insert(dad.id)
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
