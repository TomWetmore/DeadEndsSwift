//
//  GedcomTreeDisplay.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 8 November 2025.
//  Last changed on 26 November 2025.
//

import SwiftUI
import UniformTypeIdentifiers
import DeadEndsLib

/// View that displays a Gedcom tree.
struct GedcomTreeDisplay: View {
    let root: GedcomNode
    var tint: Color = .primary

    @State private var expanded: Set<UUID> = []
    @State private var consumed: Set<UUID> = []

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                GedcomTreeDisplayRow(
                    node: root,
                    expanded: $expanded,
                    consumed: $consumed,
                    level: 0,
                    tint: tint
                )
            }
        }
        .background(Color(NSColor.textBackgroundColor))
        .onAppear {
            expanded.insert(root.id)   // Expand the root when the View appears
        }
    }
}

