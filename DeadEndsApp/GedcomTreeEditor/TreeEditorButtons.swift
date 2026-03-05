//
//  TreeEditorButtons.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 8 October 2025.
//  Last changed on 5 March 2026.
//

import SwiftUI
import DeadEndsLib

/// Buttons that initiate TreeEditor actions.
struct TreeEditorButtons: View {

    @Bindable var viewModel: GedcomTreeEditorModel
    let treeManager: GedcomTreeManager

    var body: some View {
        let _ = viewModel.changeCounter  // Render change when counter increments.

        HStack {
            Button("Parent") {  // Navigate to dad node.
                viewModel.selectDad()
            }.disabled(viewModel.selectedNode?.dad == nil)

            Button("First Child") {  // Navigate to first kid node.
                viewModel.selectFirstKid()
            }.disabled(viewModel.selectedNode?.kid == nil)

            Button("Next Sib") {  // Navigate to next sib node.
                viewModel.selectNextSib()
            }.disabled(viewModel.selectedNode?.sib == nil)

            Button("Prev Sib") {  // Navigate to previous sib node.
                viewModel.selectPrevSib()
            }.disabled(viewModel.selectedNode?.prevSib == nil)

            if let selected = viewModel.selectedNode {
                Divider()
                    .frame(width: 1, height: 24)
                    .background(Color.gray)
                    .padding(.horizontal, 8)
                Button("Add Child") {  // Add a first kid to selected.
                    treeManager.addKid(GedcomNode(tag: "NEW"), to: selected)
                }.disabled(false)

                Button("Add Sib") {  // Add a next sib to selected.
                    treeManager.addSib(GedcomNode(tag: "NEW"), to: selected, dad: selected.dad!)
                }.disabled(selected.lev == 0) // No sib for root nodes.

                Button("Delete") {  // Delete selected node tree.
                    treeManager.remove(node: selected)
                }.disabled(!viewModel.canDeleteSelectedNode)
                Divider()
                    .frame(width: 1, height: 24)
                    .background(Color.gray)
                    .padding(.horizontal, 8)
                Button("Move Down") {  // Swap selected node with next sib.
                    treeManager.moveDown(node: selected)
                }.disabled(!viewModel.canMoveDownSelectedNode)

                Button("Move Up") {  // Swap seleted node with previous sib.
                    treeManager.moveUp(node: selected)
                }.disabled(!viewModel.canMoveUpSelectedNode)
            }
            Divider()
                .frame(width: 1, height: 24)
                .background(Color.gray)
                .padding(.horizontal, 8)
            Button("Undo") {
                treeManager.undo()  // Undo last edit action.
            }.disabled(!treeManager.canUndo)
            Button("Redo") {  // Redo last undone action.
                treeManager.redo()
            }.disabled(!treeManager.canRedo)
        }
        .padding()
    }
}
