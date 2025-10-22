//
//  GedcomTreeEditor.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 2 October 2025.
//  Last changed on 20 October 2025.
//

import SwiftUI
import DeadEndsLib

/// Editor for GedcomNode trees; composed of GedcomTreeEditorRows, one per each GedcomNode,
/// followed by a TreeEditorButtons view.
struct GedcomTreeEditor: View {

    @ObservedObject var viewModel: GedcomTreeEditorModel
    let manager: GedcomTreeManager
    var root: GedcomNode // Root of tree.

    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    GedcomTreeEditorRow(
                        node: root,
                        viewModel: viewModel,
                        treeManager: manager
                    )
                }
                .padding(.vertical, 4)
            }
            Divider()
            TreeEditorButtons(viewModel: viewModel, treeManager: manager)
        }
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
