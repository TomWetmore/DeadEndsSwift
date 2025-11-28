//
//  MergeWindow.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 7 November 2025.
//  Last changed on 15 November 2025.
//

import SwiftUI
import AppKit
import DeadEndsLib

/// Three pane View where Person merging occurs.
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

            // Panes for two existing Persons and a merged Person.
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
