//
//  GedcomEditorView.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 November 2025.
//  Last changed on 26 November 2025.
//

import SwiftUI
import DeadEndsLib

/// Top-level Gedcom record editor view. Contain a Header, the editable Gedcom tree, and
/// the editor buttons.
struct GedcomEditorView: View {

    @Bindable var viewModel: GedcomTreeEditorModel
    let manager: GedcomTreeManager
    var root: GedcomNode
    var title: String = "Edit Gedcom Record"

    var body: some View {
        VStack(spacing: 0) {

            // Header
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(NSColor.underPageBackgroundColor))

            Divider()

            // Editable Gedcom tree.
            GedcomTreeEditor(viewModel: viewModel, manager: manager, root: root)

            Divider()

            // Tree editing buttons
            TreeEditorButtons(viewModel: viewModel, treeManager: manager)
        }
    }
}
