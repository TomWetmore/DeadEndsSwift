//
//  GedcomEditorPage.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 November 2025.
//  Last changed on 5 March 2026.
//

import SwiftUI
import DeadEndsLib

/// Gedcom record editor page, with header, editable Gedcom tree, and edit buttons.
struct GedcomEditorPage: View {

    @State private var manager: GedcomTreeManager // Contains view model.
    var root: GedcomNode
    var title: String = "Edit Gedcom Record"

    init(database: Database, root: GedcomNode) {
        self.root = root
        _manager = State(initialValue: GedcomTreeManager(database: database, root: root))
    }

    /// Render the Gedcom editor page.
    var body: some View {
        VStack(spacing: 0) {
            HStack { Text(title).font(.headline)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(NSColor.underPageBackgroundColor))
            Divider()
            GedcomTreeEditor(viewModel: manager.treeModel, manager: manager, root: root)
            Divider()
            TreeEditorButtons(viewModel: manager.treeModel, treeManager: manager)
        }
    }
}
