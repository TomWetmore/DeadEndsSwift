//
//  GedcomTreeEditorRow.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 8 October 2025.
//  Last changed on 27 November 2025.

import SwiftUI
import DeadEndsLib

/// Builds an event summary for a level one node with no value.
func eventSummary(for node: GedcomNode) -> String? {

    guard node.val == nil, node.lev == 1 else { return nil }
    let date = node.kid(withTag: "DATE")?.val
	let place = node.kid(withTag: "PLAC")?.val
    var parts: [String] = []
    if let d = date, !d.isEmpty { parts.append(d) }
    if let p = place, !p.isEmpty { parts.append(p) }
    return parts.isEmpty ? nil : parts.joined(separator: ", ")
}

/// View for a Gedcom Tree Editor Row.
struct GedcomTreeEditorRow: View {
    var node: GedcomNode
    @Bindable var viewModel: GedcomTreeEditorModel
    let treeManager: GedcomTreeManager

    /// Body of the GedcomTreeEditorRow View.
    var body: some View {
        VStack(spacing: 0) {
            rowContent
            if viewModel.expandedSet.contains(node.uid) {
                ForEach(node.kids, id: \.uid) { kid in
                    GedcomTreeEditorRow(node: kid, viewModel: viewModel, treeManager: treeManager)
                }
            }
        }
    }

    /// Returns the Content View of a GedcomTreeEditorRow.
    private var rowContent: some View {
        GeometryReader { geo in
            HStack {
                indentView
                chevronView
                levelView
                tagText
                valueText
                Spacer()
            }
            .contentShape(Rectangle())
            .background(rowBackground)
            .onAppear { recordFrame(geo) }
            .onChange(of: geo.frame(in: .named("gedcomTree"))) { _, _ in recordFrame(geo) }

            // This block activates when session != nil (inside a MergeWorkspace)
            .draggable(DraggedGedcomSubtree(node: node))
            .dropDestination(for: DraggedGedcomSubtree.self) { items, location in
                guard let first = items.first else { return false }
                let newNode = first.toGedcomNode()

                // Checks the drop rules before before inserting.
                if !canDrop(newNode, onto: node) {
                    print("Rejected drop: level mismatch (\(newNode.lev) → \(node.lev))")  // DEBUG.
                    return false  // Drop not accepted.
                }

                // Drop is valid; do the insertion.
                handleDrop(items, location: location)
                return true
            }
        }
        .frame(height: 20)
    }

    /// View that adds the Gedcom indentation.
    private var indentView: some View {
        ForEach(0..<node.lev, id: \.self) { _ in Spacer().frame(width: 16) }
    }

    /// View that shows expanding chevron on internal nodes.
    private var chevronView: some View {
        Group {
            if node.hasKids() {
                Image(systemName: viewModel.expandedSet.contains(node.uid) ? "chevron.down" : "chevron.right")
                    .foregroundColor(.secondary)
                    .onTapGesture { viewModel.toggleExpansion(for: node) }
                    .frame(width: 16)
            } else {
                Image(systemName: "chevron.right").opacity(0).frame(width: 16)  // Invisible on leaves.
            }
        }
    }
    
    /// View that show the Gedcom level of the node.
    private var levelView: some View {
        Text("\(node.lev)")
            .frame(width: 20)
    }

    /// View that show the tag of the node.
    private var tagText: some View {
        Text(node.tag)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
    }

    /// View that shows the value text of the node.
    private var valueText: some View {
        Group {
            if let val = node.val, !val.isEmpty {
                Text(val)
            } else if let summary = eventSummary(for: node) {
                Text(summary).italic().foregroundColor(.secondary)
            }
        }
    }

    /// View that adds a background View (a Color) to the row.
    private var rowBackground: some View {
        (viewModel.selectedNode === node)
        ? Color.accentColor.opacity(0.15)
        : Color.clear
    }

    /// Finds the frame of a GedcomTreeEditorRow and stores it in a table.
    private func recordFrame(_ geo: GeometryProxy) {
        let rect = geo.frame(in: .named("gedcomTree"))
        viewModel.rowFrames[node.uid] = rect
    }

    /// Handles a drop into a Gedcom tree.
    private func handleDrop(_ items: [DraggedGedcomSubtree], location: CGPoint) {
        guard let rect = viewModel.rowFrames[node.uid] else { return }

        // See if the drop is in the upper or lower helf of the target row.
        let isUpperHalf = location.y > rect.midY

        for item in items {
            let newNode = item.toGedcomNode()

            if isUpperHalf, let parent = node.dad {
                // Drop on upper half → insert *after this node* as sibling
                print("📥 Inserting \(newNode.tag) after sibling \(node.tag)")  // DEBUG
                parent.addKidAfter(newNode, sib: node)
            } else {
                // Drop on lower half → insert *as child* of this node
                print("📥 Inserting \(newNode.tag) as child of \(node.tag)")  // DEBUG
                node.addKidAfter(newNode, sib: nil)
                viewModel.expandedSet.insert(node.uid)
            }
        }
    }

    func canDrop(_ dropped: GedcomNode, onto target: GedcomNode) -> Bool {
        // Same level as target’s existing children → allowed
        if let parent = target.dad {
            return dropped.lev == target.lev
        }
        // Root-level only allowed if both are roots
        if target.lev == 0 {
            return dropped.lev == 0
        }
        return false
    }
}
