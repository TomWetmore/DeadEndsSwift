//
//  GedcomEditorPage.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 November 2025.
//  Last changed on 2 March 2026.
//

import SwiftUI
import DeadEndsLib

/// Gedcom record editor page, with header, editable Gedcom tree, and edit buttons.
struct GedcomEditorPage: View {

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

            // Edit buttons.
            TreeEditorButtons(viewModel: viewModel, treeManager: manager)
        }
    }
}
