//
//  GedcomTreeManager.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 4 October 2025.
//  Last changed on 2 December 2025.
//

import SwiftUI
import DeadEndsLib

/// Atomic editing changes for the undo/redo stacks.
enum EditDelta {

    case addKid(kid: GedcomNode, dad: GedcomNode, sib: GedcomNode?)
    case addSib(sib: GedcomNode, prev: GedcomNode, dad: GedcomNode)
    case remove(node: GedcomNode, dad: GedcomNode, prev: GedcomNode?, sib: GedcomNode?)
    case moveUp(node: GedcomNode)
    case moveDown(node: GedcomNode)
    case editTag(node: GedcomNode, old: String, new: String)
    case editVal(node: GedcomNode, old: String, new: String)
}

/// Undo, Redo, and Edit manager for an editable Gedcom tree.
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
        treeModel.undoCounter &+= 1
    }

    /// Undo one edit operation. Deltas on the undo stack are inverted before applying.
    func undo() {
        guard let delta = undoStack.popLast() else { return } // Stack may be empty.
        applyInverse(delta)  // Apply the inverse.
        redoStack.append(delta)  // Move the delta to the redo stack.
        treeModel.undoCounter &+= 1
    }

    /// Redo one edit operation. Deltas on the redo stack are applied directly.
    func redo() {
        guard let delta = redoStack.popLast() else { return }  // Stack may be empty.
        apply(delta)  // Apply the delta directly.
        undoStack.append(delta)  // Move the delta to the undo stack.
        treeModel.undoCounter &+= 1
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
        case .editTag(node: let node, old: let old, new: let new):
            editTagCase(node: node, old: old, new: new)
        case .editVal(node: let node, old: let old, new: let new):
            editValueCase(node: node, old: old, new: new)
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
        case .editTag(node: let node, old: let old, new: let new):
            editTagCase(node: node, old: new, new: old)
        case .editVal(node: let node, old: let old, new: let new):
            editValueCase(node: node, old: new, new: old)
        }
    }
}

/// User command interface to the tree manager. These are edit commands used by the user interface. Each method
/// creates an EditDelta that is run and added to the undo stack.
extension GedcomTreeManager {

    /// Adds a kid as the first child of a dad.
    func addKid(_ kid: GedcomNode, to dad: GedcomNode) {

        print("GTM: addKid(\(kid), \(dad))")  // Debug.
        let delta = EditDelta.addKid(kid: kid, dad: dad, sib: dad.kid)
        edit(delta: delta)
    }

    /// Adds a sib as a first sib to a node.
    func addSib(_ sib: GedcomNode, to prev: GedcomNode, dad: GedcomNode) {

        print("GTM: addSib(\(sib), \(prev))")  // Debug.
        let delta = EditDelta.addSib(sib: sib, prev: prev, dad: dad)
        edit(delta: delta)
    }

    /// Removes a node (and its subtree intact) from a tree.
    func remove(node: GedcomNode) {

        print("GTM: remove(\(node))")  // Debug.
        precondition(node.dad != nil, "remove: dad cannot be nil")
        let delta = EditDelta.remove(node: node, dad: node.dad!, prev: node.prevSib, sib: node.sib)
        edit(delta: delta)
    }

    func moveUp(node: GedcomNode) {

        print("GTM: moveUp(\(node))")  // Debug.
        let delta = EditDelta.moveUp(node: node)
        edit(delta: delta)
    }

    func moveDown(node: GedcomNode) {

        print("GTM: moveDown(\(node))")  // Debug.
        let delta = EditDelta.moveDown(node: node)
        edit(delta: delta)
    }

    ///
//    func editTag(_ node: GedcomNode, from old: String, to new: String) {
//
//        guard canEditTag(node) else { return }
//        let delta = EditDelta.editTag(node: node, old: old, new: new)
//        edit(delta: delta)
//    }

    func editTag(_ node: GedcomNode, from old: String, to new: String) {
        print("editTag called for node \(node.tag), old=\(old), new=\(new)")
        print("canEditTag? \(canEditTag(node))")
        guard canEditTag(node) else {
            print("editTag aborted — canEditTag returned false")
            return
        }
        let delta = EditDelta.editTag(node: node, old: old, new: new)
        edit(delta: delta)
    }

    ///
    func editVal(_ node: GedcomNode, from old: String, to new: String) {

        guard canEditVal(node) else { return }
        let delta = EditDelta.editVal(node: node, old: old, new: new)
        edit(delta: delta)
    }
}

/// Methods in this extension run the EditDeltas and their inverses. The methods have many
/// preconditions that check invariants that must hold between associated values. Some can
/// be removed after testing.
extension GedcomTreeManager {

    func addKidCase(kid: GedcomNode, dad: GedcomNode, sib: GedcomNode?) {

        precondition(dad.kid === sib, "addKidCase: dad's kid must be sib")
        precondition(kid.dad == nil, "addKidCase: kid must be disconnected")
        precondition(kid.sib == nil, "addKidCase: kid must be disconnected")

        dad.addKid(kid)
        treeModel.expandedSet.insert(dad.id)
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

    ///
    func removeKidCase(kid: GedcomNode, dad: GedcomNode, sib: GedcomNode?) {

        precondition(kid.dad === dad, "removeKidCase: kid's dad must be dad")
        precondition(kid.sib === sib, "removeKidCase: kid's sib must be sib")
        treeModel.expandedSet.remove(kid.id)
        let dad = kid.dad   // capture BEFORE removing
        treeModel.selectedNode = dad
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
        treeModel.selectedNode = dad
    }

    private func reinsertCase(node: GedcomNode, dad: GedcomNode, prev: GedcomNode?, sib: GedcomNode?) {

        node.dad = dad
        node.sib = sib
        if let prev = prev {
            prev.sib = node
        } else {
            dad.kid = node
        }
        treeModel.selectedNode = node
    }

    private func moveUpCase(node: GedcomNode) {

        node.moveUp()
        treeModel.selectedNode = node
    }

    private func moveDownCase(node: GedcomNode) {

        node.moveDown()
        treeModel.selectedNode = node
    }

    private func editTagCase(node: GedcomNode, old: String, new: String) {

        precondition(node.tag == old, "editTagCase: node.tag is not correct")
        node.tag = new
        treeModel.textCounter &+= 1
    }

    private func editValueCase(node: GedcomNode, old: String, new: String) {

        precondition(node.val == old, "editValueCase: node.val is not correct")
        node.val = new
        treeModel.textCounter &+= 1
    }
}

// Determine tags and vals that cannot be edited in different contexts.
// Note: These should be rewritten to take into account the type of record they are in.
extension GedcomTreeManager {

    /// Protected level one tags.
    private static let protectedLevel1Tags: Set<String> = [
        "NAME", "SEX", "BIRT", "DEAT", "MARR",
        "FAMS", "FAMC", "HUSB", "WIFE", "CHIL"
    ]

    /// Protected lineage linking tags.
    public static let lineageLinkedTags: Set<String> = [
        "FAMC", "FAMS", "HUSB", "WIFE", "CHIL"
    ]

    // Protectec level two tags.
    private static let protectedLevel2Tags: Set<String> = [
        "DATE", "PLAC", "SOUR"
    ]

    /// Return whether the tag field of a node can be edited.
    func canEditTag(_ node: GedcomNode) -> Bool {

        switch node.lev {
        case 0:  // Level 0 (root) node tags cannot be edited.
            return false
        case 1:  // Some Level 1 node tags cannot be edited.
            return !Self.protectedLevel1Tags.contains(node.tag)
        case 2:  // Some level 2 node tags cannot be edited.
            return !Self.protectedLevel2Tags.contains(node.tag)
        default:
            return true
        }
    }

    /// Return whether the val field of a node can be edited.
    func canEditVal(_ node: GedcomNode) -> Bool {

        let level = node.lev
        if level == 0 {  // Level 0 nodes (roots) cannot be edited.
            return false
        }
        if level == 1 && Self.lineageLinkedTags.contains(node.tag) {  // Lineage nodes cannot be edited.
            return false
        }
        return true
    }
}
