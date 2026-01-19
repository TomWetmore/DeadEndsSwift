//
//  MergeWindow.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 7 November 2025.
//  Last changed on 3 January 2026.
//

import SwiftUI
import DeadEndsLib

/// Three pane Window where Person merging happens. The side panes are wrapped PersonTreeDisplays and the
/// central pane is a wrapped GedcomTreeEditor.

struct MergeWindow: View {

    @StateObject private var session = MergeSession()

    var left: Person
    var right: Person
    var onCancel: () -> Void

    var body: some View {
        
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Cancel") { onCancel() }
            }
            Divider()

            // Panes for two existing Persons and the merged Person.
            HSplitView {

                SideMergePane(person: left, tint: .blue)
                    .frame(minWidth: 250, idealWidth: 400, maxWidth: .infinity)

                CenterMergePane()
                    .frame(minWidth: 250, idealWidth: 400, maxWidth: .infinity)

                SideMergePane(person: right, tint: .orange)
                    .frame(minWidth: 250, idealWidth: 400, maxWidth: .infinity)
            }
            .environmentObject(session)
            .frame(minWidth: 800, minHeight: 600)
        }
    }
}

/// View for the side panes shown in the MergeWindow. It is a wrapper around a GedcomTreeDisplay View.

struct SideMergePane: View {

    let person: Person
    let tint: Color

    var body: some View {
        
        VStack {
            Text(person.displayName())
            Divider()
            GedcomTreeDisplay(root: person.root, tint: tint)
        }
    }
}
