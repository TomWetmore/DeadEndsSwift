//
//  GedcomTreeManager.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 4 October 2025.
//  Last changed on 26 November 2025.
//

import SwiftUI
import DeadEndsLib

enum EditDelta {
    case addKid(kid: GedcomNode, dad: GedcomNode, sib: GedcomNode?)
    case addSib(sib: GedcomNode, prev: GedcomNode, dad: GedcomNode)
    case remove(node: GedcomNode, dad: GedcomNode, prev: GedcomNode?, sib: GedcomNode?)
    case moveUp(node: GedcomNode)
    case moveDown(node: GedcomNode)
}

/// Undo, Redo, and Edit manager for a Gedcom tree.
@MainActor
final class GedcomTreeManager {

    let treeModel: GedcomTreeEditorModel
    let recordIndex: RecordIndex

    private var undoStack: [EditDelta] = []
    private var redoStack: [EditDelta] = []


    init(database: Database) {
        self.recordIndex = database.recordIndex // Needed?
        self.treeModel = GedcomTreeEditorModel()
    }

    // Convenience init for isolated use (like MergeEditorView).
    init(treeModel: GedcomTreeEditorModel, recordIndex: RecordIndex) {
        self.treeModel = treeModel
        self.recordIndex = recordIndex
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    /// Handle a new delta from the user interface. Apply the delta and add it to the undo stack.
    func edit(delta: EditDelta) {
        apply(delta)
        undoStack.append(delta)
        redoStack.removeAll()
    }

    /// Undo one edit operation. Deltas on the undo stack are inverted before applying.
    func undo() {
        guard let delta = undoStack.popLast() else { return } // Stack may be empty.
        applyInverse(delta)  // Apply the inverse.
        redoStack.append(delta)  // Move the delta to the redo stack.
    }

    /// Redo one edit operation. Deltas on the redo stack are applied directly.
    func redo() {
        guard let delta = redoStack.popLast() else { return }  // Stack may be empty.
        apply(delta)  // Apply the delta directly.
        undoStack.append(delta)  // Move the delta to the undo stack.
    }

    /// Applies an EditDelta to the Gedcom tree.
    private func apply(_ delta: EditDelta) {
        switch delta {
        case let .addKid(kid, dad, sib):
            addKidCase(kid: kid, dad: dad, sib: sib)
        case let .addSib(sib, prev, dad):
            addSibCase(sib: sib, prev: prev, dad: dad)
        case let .remove(node: node, dad: dad, prev: prev, sib: sib):
            removeCase(node: node, dad: dad, prev: prev, sib: sib)
        case let .moveUp(node: node):
            moveUpCase(node: node)
        case let .moveDown(node: node):
            moveDownCase(node: node)
        }
    }

    /// Applies the inverse of an EditDelta (undoes its effects) to the Gedcom tree.
    private func applyInverse(_ delta: EditDelta) {
        switch delta {
        case let .addKid(kid: kid, dad: dad, sib: sib):
            removeKidCase(kid: kid, dad: dad, sib: sib)
        case let .addSib(sib: sib, prev: prev, dad: dad):
            removeSibCase(sib: sib, prev: prev, dad: dad)
        case let .remove(node: node, dad: dad, prev: prev, sib: sib):
            reinsertCase(node: node, dad: dad, prev: prev, sib: sib)
        case let .moveUp(node: node):
            moveDownCase(node: node)
        case let .moveDown(node: node):
            moveUpCase(node: node)
        }
    }
}

/// User command interface to the tree manager. These are edit commands used by the user interface. Each method
/// creates an EditDelta that is run and added to the undo stack.
extension GedcomTreeManager {

    /// Adds a kid as the first child of a dad.
    func addKid(_ kid: GedcomNode, to dad: GedcomNode) {
        let delta = EditDelta.addKid(kid: kid, dad: dad, sib: dad.kid)
        edit(delta: delta)
    }

    /// Adds a sib as a first sib to a node.
    func addSib(_ sib: GedcomNode, to prev: GedcomNode, dad: GedcomNode) {
        let delta = EditDelta.addSib(sib: sib, prev: prev, dad: dad)
        edit(delta: delta)
    }

    /// Removes a node (and its subtree intact) from a tree.
    func remove(node: GedcomNode) {
        precondition(node.dad != nil, "remove: dad cannot be nil")
        let delta = EditDelta.remove(node: node, dad: node.dad!, prev: node.prevSib, sib: node.sib)
        edit(delta: delta)
    }

    func moveUp(node: GedcomNode) {
        let delta = EditDelta.moveUp(node: node)
        edit(delta: delta)
    }

    func moveDown(node: GedcomNode) {
        let delta = EditDelta.moveDown(node: node)
        edit(delta: delta)
    }
}

/// Methods in this extension run the EditDeltas and their inverses. The methods have many preconditions that check
/// invariants between the associated values. Some can likly be removed after thorough testing.
extension GedcomTreeManager {
    func addKidCase(kid: GedcomNode, dad: GedcomNode, sib: GedcomNode?) {
        precondition(dad.kid === sib, "addKidCase: dad's kid must be sib")
        precondition(kid.dad == nil, "addKidCase: kid must be disconnected")
        precondition(kid.sib == nil, "addKidCase: kid must be disconnected")

        dad.addKid(kid)
        treeModel.expandedSet.insert(dad.uid)
        treeModel.selectedNode = kid
    }

    func addSibCase(sib: GedcomNode, prev: GedcomNode, dad: GedcomNode) {
        precondition(prev.dad === dad, "addSibCase: prev does not have right dad")
        precondition(sib.dad === nil, "addSibCase: sib must be disconnected")
        precondition(sib.sib == nil, "addSibCase: sib must be disconnected")

        prev.addSib(sib)
        precondition(sib.dad === dad, "addSibCase: sib does not have right dad")
        precondition(prev.sib === sib, "addSibCase: prev has wrong sib")
        treeModel.selectedNode = sib;
    }

    func removeKidCase(kid: GedcomNode, dad: GedcomNode, sib: GedcomNode?) {
        precondition(kid.dad === dad, "removeKidCase: kid's dad must be dad")
        precondition(kid.sib === sib, "removeKidCase: kid's sib must be sib")
        treeModel.expandedSet.remove(kid.uid)
        if let dad = kid.dad { treeModel.selectedNode = dad }
        kid.removeKid()
    }

    func removeSibCase(sib: GedcomNode, prev: GedcomNode, dad: GedcomNode) {
        precondition(sib.dad === dad, "removeSibCase: sib.dad === dad")
        precondition(prev.dad === dad, "removeSibCase: prev.dad === dad")
        precondition(prev.sib === sib, "removeSibCase: prev.sib === sib")
        prev.sib = sib.sib
        sib.dad = nil
        sib.sib = nil
    }

    func removeCase(node: GedcomNode, dad: GedcomNode, prev: GedcomNode?, sib: GedcomNode?) {
        precondition(node.dad === dad, "removeCase: node.dad !== dad")
        precondition(node.sib === sib, "removeCase: node.sib !== sib")
        if let prev = prev {
            precondition(prev.dad === dad, "removeCase: prev.dad !== dad")
            precondition(prev.sib === node, "removeCase: prev.sib !== node")
        }
        if let sib = sib {
            precondition(sib.dad === dad, "removeCase: sib.dad !== dad")
        }
        if prev == nil {
            dad.kid = sib
        } else {
            prev!.sib = sib
        }
        node.dad = nil
        node.sib = nil
    }

    private func reinsertCase(node: GedcomNode, dad: GedcomNode, prev: GedcomNode?, sib: GedcomNode?) {
        node.dad = dad
        node.sib = sib
        if let prev = prev {
            prev.sib = node
        } else {
            dad.kid = node
        }
    }

    private func moveUpCase(node: GedcomNode) {
        node.moveUp()
    }

    private func moveDownCase(node: GedcomNode) {
        node.moveDown()
    }
}

// Determine tags and vals that cannot be edited in different contexts.
// Note: These should be rewritten to take into account the type of record they are in.
extension GedcomTreeManager {

    // MARK: - Static tag lists
    private static let protectedLevel1Tags: Set<String> = [
        "NAME", "SEX", "BIRT", "DEAT", "MARR",
        "FAMS", "FAMC", "HUSB", "WIFE", "CHIL"
    ]

    public static let lineageLinkedTags: Set<String> = [
        "FAMC", "FAMS", "HUSB", "WIFE", "CHIL"
    ]

    private static let protectedLevel2Tags: Set<String> = [
        "DATE", "PLAC", "SOUR"
    ]

    /// Returns whether the tag field of a GedcomNode can be edited.
    func canEditTag(_ node: GedcomNode) -> Bool {
        let level = node.lev

        switch level {
        case 0:
            // Root tags of records (INDI, FAM, etc.) should not be edited
            return false
        case 1:
            return !Self.protectedLevel1Tags.contains(node.tag)
        case 2:
            return !Self.protectedLevel2Tags.contains(node.tag)
        default:
            return true
        }
    }

    /// Returns whether the val field of a GedcomNode can be edited.
    func canEditVal(_ node: GedcomNode) -> Bool {
        let level = node.lev

        // Lev 0 vals cannot have values.
        if level == 0 {
            return false
        }

        // Protect vals of tags that are links to other records.
        if level == 1 && Self.lineageLinkedTags.contains(node.tag) {
            return false
        }

        return true
    }
}
