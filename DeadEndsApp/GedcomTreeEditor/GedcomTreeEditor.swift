//
//  GedcomTreeEditor.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 2 October 2025.
//  Last changed on 4 January 2026.
//

import SwiftUI
import DeadEndsLib

/// GedcomTreeEditor
///
/// A stateless, dependency-injected SwiftUI view that renders a Gedcom node tree.
/// This view owns no model and performs no mutation: all
/// state, behavior, and editing actions are provided by the wrapper
/// environment.
///
/// Requirements:
///   - `GedcomTreeEditorModel` supplied via @Bindable
///   - `GedcomTreeManager` supplied as a command handler
///   - A root `GedcomNode` provided by the parent context
///
/// This design intentionally allows the tree editor to be embedded in
/// multiple contexts (e.g. editing a Person, a Family, or a standalone
/// GEDCOM viewer) as long as the surrounding container provides the
/// model and manager it depends on.
///
/// Pattern:
///   - Container/Presentational separation
///   - Stateless rendering view (presentation layer)
///   - Dependency-injected model and controller
///
/// This view should never create or own its own state; ownership of the
/// editor model must remain in the container (e.g. `GedcomEditorWindow`).
/// Displays an editable Gedcom record as a Gedcom tree. The View is composed of GedcomTreeEditorRows,
/// one for each visible GedcomNode.
/// This view is tree only; it has no buttons or framing. Currently it has two uses.
/// 1. It is invoked by the GedcomEditorWindow which wires it up and provides the editor buttons.
/// 2. It is invoked by the CentralMergePane of the MergeWindow.
///
struct GedcomTreeEditor: View {

    @Bindable var viewModel: GedcomTreeEditorModel
    let manager: GedcomTreeManager
    var root: GedcomNode

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

// Optional binding helper
//extension Binding where Value == String? {
//
//    var bound: Binding<String> {
//        Binding<String>(
//            get: { self.wrappedValue ?? "" },
//            set: { self.wrappedValue = $0.isEmpty ? nil : $0 }
//        )
//    }
//}







