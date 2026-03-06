//
//  GedcomEditorPage.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 November 2025.
//  Last changed on 6 March 2026.

/// GedcomEditorPage is one of the DeadEnds page views. Its two main components
/// are a GedcomTreeEditor view and a TreeEditorButtons view. Those views need
/// a GedcomTreeManager and a GedcomTreeModel. This view create the manager as
/// a @State property and the manager creates the model object.

import SwiftUI
import DeadEndsLib

/// Gedcom record editor page, with header, editable Gedcom tree, and edit buttons.
struct GedcomEditorPage: View {
    @State private var manager: GedcomTreeManager // Contains view model.
    var root: GedcomNode
    var title: String = "Edit Gedcom Record"

    /// Create a Gedcom editor page, which also create the manager and model.
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
