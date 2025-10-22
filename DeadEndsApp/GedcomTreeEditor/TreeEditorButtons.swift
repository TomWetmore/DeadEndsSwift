//
//  TreeEditorButtons.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 8 October 2025.
//  Last changed on 20 October 2025.
//

import SwiftUI
import DeadEndsLib

/// Buttons used for TreeEditor actions; may be replaced or augmented with other ways to perform the actions.
struct TreeEditorButtons: View {

    // Need both the tree model and tree manager to do the actions.
    @ObservedObject var viewModel: GedcomTreeEditorModel
    let treeManager: GedcomTreeManager

    var body: some View {
        HStack {
            // Buttons that navigate and select nodes.
            Button("Parent") {
                viewModel.selectDad()
            }.disabled(viewModel.selectedNode?.dad == nil)

            Button("First Child") {
                viewModel.selectFirstKid()
            }.disabled(viewModel.selectedNode?.kid == nil)

            Button("Next Sib") {
                viewModel.selectNextSib()
            }.disabled(viewModel.selectedNode?.sib == nil)

            Button("Prev Sib") {
                viewModel.selectPrevSib()
            }.disabled(viewModel.selectedNode?.prevSib == nil)

            // Buttons that modify the tree.
            if let selected = viewModel.selectedNode {
                Divider()
                    .frame(width: 1, height: 24)
                    .background(Color.gray)
                    .padding(.horizontal, 8)

                Button("Add Child") {
                    treeManager.addKid(GedcomNode(tag: "NEW"), to: selected)
                }.disabled(false) // All(?) nodes can have siblings added.

                Button("Add Sib") {
                    treeManager.addSib(GedcomNode(tag: "NEW"), to: selected, dad: selected.dad!) // TODO: Remove forced unwrap.
                }.disabled(selected.lev == 0) // Can't add siblings to root nodes.

                Button("Delete") {
                    treeManager.remove(node: selected)
                }.disabled(!viewModel.canDeleteSelectedNode) // Several nodes can't be deleted.


                // Buttons the move siblings relative to each other.
                Divider()
                    .frame(width: 1, height: 24)
                    .background(Color.gray)
                    .padding(.horizontal, 8)
                Button("Move Down") {
                    treeManager.moveDown(node: selected)
                }.disabled(!viewModel.canMoveDownSelectedNode)

                Button("Move Up") {
                    treeManager.moveUp(node: selected)
                }.disabled(!viewModel.canMoveUpSelectedNode)
            }

            // Buttons that undo and redo changes.
            Divider()
                .frame(width: 1, height: 24)
                .background(Color.gray)
                .padding(.horizontal, 8)
            Button("Undo") {
                treeManager.undo()
            }.disabled(!treeManager.canUndo)

            Button("Redo") {
                treeManager.redo()
            }.disabled(!treeManager.canRedo)
        }
        .padding()
    }
}
