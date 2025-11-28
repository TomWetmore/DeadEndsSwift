//
//  GedcomTreeEditor.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 2 October 2025.
//  Last changed on 15 November 2025.
//

import SwiftUI
import DeadEndsLib

/// Displays a Gedcom record tree that can be edited. The View is composed of GedcomTreeEditor Rows, one
/// per GedcomNode. This view is tree only; it has no buttons or framing. Currently it has two uses.
/// 1. It is invoked by the GedcomEditorView which wires it up and provides the editor buttons.
/// 2. It is invoked by the CentralMergePane of the MergeWindow.
struct GedcomTreeEditor: View {
    @Bindable var viewModel: GedcomTreeEditorModel
    let manager: GedcomTreeManager
    var root: GedcomNode

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                GedcomTreeEditorRow(node: root, viewModel: viewModel, treeManager: manager)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .coordinateSpace(name: "gedcomTree")
    }
}

// Optional binding helper
extension Binding where Value == String? {
    var bound: Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? "" },
            set: { self.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}
