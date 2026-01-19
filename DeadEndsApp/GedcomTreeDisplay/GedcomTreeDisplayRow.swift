//
//  GedcomTreeDisplayRow.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 1 Decenber 2025.
//  Last changed on 1 December 2025.
//

import SwiftUI
import DeadEndsLib

/// Read-only row used by GedcomTreeDisplay to show a GedcomNode. Rows are collapsible. Rows
/// are potential drag sources. Tint can be used for provenance, say in merge operations.
struct GedcomTreeDisplayRow: View {

    let node: GedcomNode
    @Binding var expanded: Set<UUID>  // Nodes whose IDs are open
    @Binding var consumed: Set<UUID>  // Nodes that have been consumed (dragged away).
    var level: Int
    var tint: Color
    var allowDrag: Bool = true

    /// Main view is a list of visible lines from a Gedcom record.
    var body: some View {
        VStack(spacing: 0) {
            rowContent
            if expanded.contains(node.id) {
                ForEach(node.kids, id: \.id) { kid in
                    GedcomTreeDisplayRow(
                        node: kid,
                        expanded: $expanded,
                        consumed: $consumed,
                        level: level + 1,
                        tint: tint,
                        allowDrag: allowDrag
                    )
                }
            }
        }
    }

    /// View showing one Gedcom line as an HStack of individual fields.
    private var rowContent: some View {
        HStack {
            indentView  // Indent.
            chevronView  // Disclosure chevron.
            levelView  // Level.
            keyView  // Key if node is a root.
            tagText  // Tag of node.
            valueText  // Value if node has one, possibly constructed event summary.
            Spacer()
        }
        .monospaced()
        .padding(.horizontal, 10)
        .padding(.vertical, 2)
        .background(Color.clear)
        .contentShape(Rectangle())
        .opacity(consumed.contains(node.id) ? 0.3 : 1.0)
        .allowsHitTesting(!consumed.contains(node.id))
    }

    /// Marks a node and all its descendents as consumed.
    private func consumeSubtree(_ node: GedcomNode) {
        consumed.insert(node.id)
        for child in node.kids {
            consumeSubtree(child)
        }
    }

    // Indent subview that indents lines.
    private var indentView: some View {
        ForEach(0..<level, id: \.self) { _ in
            Spacer().frame(width: 16)
        }
    }

    // Chevron subview shows the disclosure chevron on nodes with children.
    private var chevronView: some View {
        Group {
            if node.hasKids() {
                Image(systemName: expanded.contains(node.id) ? "chevron.down" : "chevron.right")
                    .foregroundColor(.secondary)
                    .onTapGesture {
                        toggleExpansion(for: node)
                    }
                    .frame(width: 16)
            } else {  // Show an invisible chevron on leaves to keep the spacing correct.
                Image(systemName: "chevron.right")
                    .opacity(0)
                    .frame(width: 16)
            }
        }
    }

    /// Level subview shows the Gedcom level of the line.
    private var levelView: some View {
        Text("\(node.lev)")
            .frame(width: 12)
            .foregroundColor(.secondary)
    }

    /// keyView shows the key, complete with @-signs, on root nodes.
    private var keyView: some View {
        Group {
            if let key = node.key {
                Text(key)
                    .foregroundColor(.blue)
                    .font(.title3)
            }
        }
    }

    /// tagText show the tag, mandatory on all nodes.
    private var tagText: some View {
        Text(node.tag)
            .foregroundColor(tint)
            .fontWeight(.semibold)
            .frame(width: 36, alignment: .leading)
    }

    /// valueText shows the value field, if present.
    private var valueText: some View {
        Group {
            if let val = node.val, !val.isEmpty {  // Show the value if there.
                Text(val)
                    .foregroundColor(.primary)
            } else if let summary = eventSummary(for: node) {  // Try to summarize an event when no value.
                Text(summary)
                    .italic()
                    .foregroundColor(.secondary)
            }
        }
    }

    // Toggles the expansion/disclosure state of a node.
    private func toggleExpansion(for node: GedcomNode) {
        if expanded.contains(node.id) {
            expanded.remove(node.id)
        } else {
            expanded.insert(node.id)
        }
    }
}
