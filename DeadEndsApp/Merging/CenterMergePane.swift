//
//  CenterMergePane.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 9 November 2025.
//  Last changed on 3 January 2026.
//

import SwiftUI
import DeadEndsLib

/// Central editable pane of the MergeWindow. Accepts dropped Gedcom subtrees from side panels
/// and allows in-place editing.

struct CenterMergePane: View {

    @State private var mergedRoot: GedcomNode = GedcomNode(tag: "INDI")
    @State private var viewModel: GedcomTreeEditorModel
    @State private var manager: GedcomTreeManager
    @EnvironmentObject private var session: MergeSession

    init() {
        
        let model = GedcomTreeEditorModel(root: nil)
        let index = RecordIndex()
        _viewModel = State(wrappedValue: model)
        _manager = State(
            wrappedValue: GedcomTreeManager(treeModel: model,
                                            recordIndex: index)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            GedcomTreeEditor(viewModel: viewModel, manager: manager, root: mergedRoot)
        }
        .frame(minWidth: 300)
        .background(Color(NSColor.textBackgroundColor))
        .dropDestination(for: DraggedGedcomSubtree.self) { items, location in
            handleDrop(items, location: location)
            return true
        }
    }

    /// Drop handler
    func handleDrop(_ items: [DraggedGedcomSubtree], location: CGPoint) {
        // Root node is about to change.
        print("Drop mergedRoot:", ObjectIdentifier(mergedRoot))  // DEBUG

        for item in items {
            print("📥 Dropped subtree for tag:", item.tag)  // DEBUG
            let newNode = item.toGedcomNode()
            mergedRoot.addSubtree(newNode)
        }

        // Expand the root and its new children so they are visible
        viewModel.expandedSet.insert(mergedRoot.id)
        for kid in mergedRoot.kids {
            viewModel.expandedSet.insert(kid.id)
        }
        print("✅ After drop: \(mergedRoot.kids.count) kids now attached to root")  // DEBUG
    }

    private var header: some View {
        HStack {
            Text("Merged Record").font(.headline)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}
