//
//  GedcomEditorWindow.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 November 2025.
//  Last changed on 30 November 2025.
//

import SwiftUI
import DeadEndsLib

/// Composit Gedcom record editor window. Contains a header, an editable Gedcom Tree, and
/// the editor buttons.
struct GedcomEditorWindow: View {

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

            // Tree editing buttons.
            TreeEditorButtons(viewModel: viewModel, treeManager: manager)
        }
    }
}
