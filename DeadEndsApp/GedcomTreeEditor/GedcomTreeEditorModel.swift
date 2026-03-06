//
//  GedcomTreeEditorModel.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 2 October 2025.
//  Last changed on 6 March 2026.

/// GedcomTreeEditorModel represents the state of the Gedcom tree editor as seen
/// by the user interface. It contains the information needed to render the tree
/// and track UI interaction state such as selection, expansion, and editing context.
/// The model does not modify the underlying Gedcom records directly; it serves
/// as the observable bridge between the database and the SwiftUI views.

import SwiftUI
import DeadEndsLib

/// Model for a GedcomTreeEditor -- tracks the selected and expanded nodes.
@MainActor
@Observable
final class GedcomTreeEditorModel {

    var expandedSet: Set<UUID> = []
    var selectedNode: GedcomNode? = nil
    var rowFrames: [UUID: CGRect] = [:]
    var changeCounter: Int = 0

    /// Create model with a selected node with kids.
    convenience init(root: GedcomNode? = nil) {
        self.init(root: root, showKids: true)
    }

    /// Create model with selected node and kids if flag is true.
    init(root: GedcomNode? = nil, showKids: Bool = true) {
        self.selectedNode = root
        guard let root else { return }
        if showKids { expandedSet = [root.id] }
    }

    /// Toggle the expanded state of a node and select it.
    func toggleExpansion(for node: GedcomNode) {
        if expandedSet.contains(node.id) {
            expandedSet.remove(node.id)
        } else {
            expandedSet.insert(node.id)
        }
        selectedNode = node
    }

    /// Check if the selected node can be removed from its tree.
    var canDeleteSelectedNode: Bool {
        guard let node = selectedNode else { return false }
        if node.lev == 0 { return false }
        if node.lev == 1 && GedcomTreeManager.lineageLinkedTags.contains(node.tag) { return false }
        return true
    }

    /// Check if the selected node can be moved after its next sib.
    var canMoveDownSelectedNode: Bool {
        guard let node = selectedNode else { return false }
        return node.sib != nil
    }

    /// Check if the selected node can be moved before its previous sib.
    var canMoveUpSelectedNode: Bool {
        guard let node = selectedNode
        else { return false }
        return node.prevSib != nil
    }

    /// Select the dad of the selected node.
    func selectDad() {
        guard let node = selectedNode, let parent = node.dad
        else { return }
        selectedNode = parent
    }

    /// Select the first kid of the selected node.
    func selectFirstKid() {
        guard let dad = selectedNode, let kid = dad.kid
        else { return }
        expandedSet.insert(dad.id)
        selectedNode = kid
    }

    /// Select the next sib of the selected node.
    func selectNextSib() {
        guard let node = selectedNode, let next = node.sib
        else { return }
        selectedNode = next
    }

    /// Select the previous sib of the selected node.
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
