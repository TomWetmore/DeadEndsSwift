//
//  GedcomTreeEditor.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 2 October 2025.
//  Last changed on 6 March 2026.

/// GedcomTreeEditor is a SwiftUI view that renders a Gedcom node tree. This
/// view is a scrolling vertical stack of GedcomTreeEditorRows. The row view
/// is recursive so this view renders only the root row; the others are
/// rendered from within row view.
///
/// This view is stateless and does not use the manager or model, simply
/// passing them down to the rows. This allows the tree editor to be embedded
/// in different contexts with surrounding containers that provide the model
/// and manager.

import SwiftUI
import DeadEndsLib

/// Gedcom tree editor.
struct GedcomTreeEditor: View {
    @Bindable var viewModel: GedcomTreeEditorModel
    let manager: GedcomTreeManager
    var root: GedcomNode

    /// Render the Gedcom tree editor.
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                GedcomTreeEditorRow(viewModel: viewModel, treeManager: manager, node: root)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .coordinateSpace(name: "gedcomTree")
    }
}
