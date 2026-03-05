//
//  GedcomTreeManager.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 4 October 2025.
//  Last changed on 4 March 3026.

/// GedcomTreeManager makes all the actual changes to the Gedcom tree being
/// edited. It applies changes to the underlying Gedcom node structures while
/// preserving the structural invariants of the tree and maintaining consistency
/// with the database. The manager receives editing requests from the UI layer
/// and converts them into safe operations on the Gedcom data.
///
/// It maintains an 'infinite' undo/redo stack.
///
/// Executes editing operations on the Gedcom tree, ensuring that all changes
/// preserve the structural invariants of the node graph and remain consistent
/// with the underlying database.

import SwiftUI
import DeadEndsLib

/// Atomic edit changes for the undo/redo stacks.
enum EditDelta {
    case addKid(kid: GedcomNode, dad: GedcomNode, sib: GedcomNode?)
    case addSib(sib: GedcomNode, prev: GedcomNode, dad: GedcomNode)
    case remove(node: GedcomNode, dad: GedcomNode, prev: GedcomNode?, sib: GedcomNode?)
    case moveUp(node: GedcomNode)
    case moveDown(node: GedcomNode)
    case editTag(node: GedcomNode, old: String, new: String)
    case editVal(node: GedcomNode, old: String?, new: String?)
}

/// Undo, Redo, and Edit manager for an editable Gedcom tree.
@MainActor
final class GedcomTreeManager {

    let treeModel: GedcomTreeEditorModel
    let recordIndex: RecordIndex
    private var undoStack: [EditDelta] = []
    private var redoStack: [EditDelta] = []

    /// Create manager: the version that creates the model with record root.
    init(database: Database, root: GedcomNode) {
        self.recordIndex = database.recordIndex
        self.treeModel = GedcomTreeEditorModel(root: root)
    }

    /// Return true if there is another undo.
    var canUndo: Bool { !undoStack.isEmpty }

    /// Return true if there is another redo.
    var canRedo: Bool { !redoStack.isEmpty }

    /// Handle delta from the user interface; apply delta and add to the undo stack.
    func edit(delta: EditDelta) {
        apply(delta)
        undoStack.append(delta)
        redoStack.removeAll()
        treeModel.changeCounter &+= 1
    }

    /// Undo last delta and move to the redo stack; invert delta before applying.
    func undo() {
        guard let delta = undoStack.popLast() else { return }
        applyInverse(delta)
        redoStack.append(delta)
        treeModel.changeCounter &+= 1
    }

    /// Redo delta on redo stack and move it to the undo stack.
    func redo() {
        guard let delta = redoStack.popLast() else { return }
        apply(delta)
        undoStack.append(delta)
        treeModel.changeCounter &+= 1
    }

    /// Apply delta to the Gedcom tree.
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

    /// Apply delta inverse to the Gedcom tree.
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

/// User interface to tree manager; each method creates a delta that is run and stacked
/// on the undo stack.
extension GedcomTreeManager {

    /// Add a node as the first kid of a dad.
    func addKid(_ kid: GedcomNode, to dad: GedcomNode) {
        let delta = EditDelta.addKid(kid: kid, dad: dad, sib: dad.kid)
        edit(delta: delta)
    }

    /// Add a node as the first sib of a node.
    func addSib(_ sib: GedcomNode, to prev: GedcomNode, dad: GedcomNode) {
        let delta = EditDelta.addSib(sib: sib, prev: prev, dad: dad)
        edit(delta: delta)
    }

    /// Remove a node and its descendants from a tree.
    func remove(node: GedcomNode) {
        precondition(node.dad != nil, "remove: dad cannot be nil")
        let delta = EditDelta.remove(node: node, dad: node.dad!, prev: node.prevSib, sib: node.sib)
        edit(delta: delta)
    }

    /// Move a node back one space in its sib chain.
    func moveUp(node: GedcomNode) {
        let delta = EditDelta.moveUp(node: node)
        edit(delta: delta)
    }

    /// Move a node ahead one space in its sib chain.
    func moveDown(node: GedcomNode) {
        let delta = EditDelta.moveDown(node: node)
        edit(delta: delta)
    }

    /// Change a tag in the tree.
    func editTag(_ node: GedcomNode, from old: String, to new: String) {
        guard canEditTag(node) else { return }
        let delta = EditDelta.editTag(node: node, old: old, new: new)
        edit(delta: delta)
    }

    /// Change a value in the tree.
    func editVal(_ node: GedcomNode, from old: String?, to new: String?) {
        guard canEditVal(node) else { return }
        let delta = EditDelta.editVal(node: node, old: old, new: new)
        edit(delta: delta)
    }
}

/// Methods that run the delta and their inverses; many assertions currenttly run;
extension GedcomTreeManager {

    /// Add a kid to the tree and update tree model.
    func addKidCase(kid: GedcomNode, dad: GedcomNode, sib: GedcomNode?) {
        precondition(dad.kid === sib, "addKidCase: dad's kid must be sib")
        precondition(kid.dad == nil, "addKidCase: kid must be disconnected")
        precondition(kid.sib == nil, "addKidCase: kid must be disconnected")

        dad.addKid(kid)
        treeModel.expandedSet.insert(dad.id)
        treeModel.selectedNode = kid
    }

    /// Add a sib to a node and update tree model.
    func addSibCase(sib: GedcomNode, prev: GedcomNode, dad: GedcomNode) {
        precondition(prev.dad === dad, "addSibCase: prev does not have right dad")
        precondition(sib.dad === nil, "addSibCase: sib must be disconnected")
        precondition(sib.sib == nil, "addSibCase: sib must be disconnected")

        prev.addSib(sib)
        precondition(sib.dad === dad, "addSibCase: sib does not have right dad")
        precondition(prev.sib === sib, "addSibCase: prev has wrong sib")
        treeModel.selectedNode = sib;
    }

    /// Remove a node and its descendants and update tree model.
    func removeKidCase(kid: GedcomNode, dad: GedcomNode, sib: GedcomNode?) {
        precondition(kid.dad === dad, "removeKidCase: kid's dad must be dad")
        precondition(kid.sib === sib, "removeKidCase: kid's sib must be sib")

        treeModel.expandedSet.remove(kid.id)
        let dad = kid.dad   // capture BEFORE removing
        treeModel.selectedNode = dad
        kid.removeKid()
    }

    /// Remove ...
    func removeSibCase(sib: GedcomNode, prev: GedcomNode, dad: GedcomNode) {
        precondition(sib.dad === dad, "removeSibCase: sib.dad === dad")
        precondition(prev.dad === dad, "removeSibCase: prev.dad === dad")
        precondition(prev.sib === sib, "removeSibCase: prev.sib === sib")
        prev.sib = sib.sib
        sib.dad = nil
        sib.sib = nil
    }

    /// Remove ...
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

    /// Reinsert a node in the tree.
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

    /// Move node back one step in its sib chain.
    private func moveUpCase(node: GedcomNode) {
        node.moveUp()
        treeModel.selectedNode = node
    }

    /// Move node down one step in its sib chain.
    private func moveDownCase(node: GedcomNode) {
        node.moveDown()
        treeModel.selectedNode = node
    }

    /// Change tag.
    private func editTagCase(node: GedcomNode, old: String, new: String) {
        precondition(node.tag == old, "editTagCase: node.tag is not correct")
        node.tag = new
        treeModel.changeCounter &+= 1
    }

    /// Change value.
    private func editValueCase(node: GedcomNode, old: String?, new: String?) {
        precondition(node.val == old, "editValueCase: node.val is not correct")
        node.val = new
        treeModel.changeCounter &+= 1
    }
}

// Tags and vals that cannot be edited in different contexts; context should be used. // TODO
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
