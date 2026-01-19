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
            expanded.insert(root.uid)   // Expand the root when the View appears
        }
    }
}

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
            if expanded.contains(node.uid) {
                ForEach(node.kids, id: \.uid) { kid in
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
        .opacity(consumed.contains(node.uid) ? 0.3 : 1.0)
        .allowsHitTesting(!consumed.contains(node.uid))
        .if(allowDrag && !consumed.contains(node.uid)) { view in
//            view.draggable({
//                consumeSubtree(node)  // Mark node consumed when drag starts (TO BE CHANGED).
//                print("Dragging \(node.tag)")  // DEBUG
//                for k in node.kids { // DEBUG
//                    print("  kid → \(k.tag)") // DEBUG
//                }
//                return DraggedGedcomSubtree(node: node)
//            }())

            view.draggable(DraggedGedcomSubtree(node: node))
            
        }
    }

    /// Marks a node and all its descendents as consumed.
    private func consumeSubtree(_ node: GedcomNode) {
        consumed.insert(node.uid)
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
                Image(systemName: expanded.contains(node.uid) ? "chevron.down" : "chevron.right")
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
        if expanded.contains(node.uid) {
            expanded.remove(node.uid)
        } else {
            expanded.insert(node.uid)
        }
    }
}

/// Transferable wrapper for dragging a Gedcom subtree.
/// Codable —- specifies how to encode/decode to JSON or other serial format.
/// Transferable -- specifies how to move between drag sources and drop targets.
struct DraggedGedcomSubtree: Transferable, Codable {

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }

    // These are the values that are serialized.
    var tag: String
    var val: String?
    var children: [DraggedGedcomSubtree]

    /// Creates a DraggedGedcomSubtree from a GedcomNode and its descendents. It converts a
    /// GedcomNode into a transferrable representation of the node and all its descendents.
    /// This happens at 'drag time.'
    init(node: GedcomNode) {
        self.tag = node.tag
        self.val = node.val
        self.children = node.kids.map { DraggedGedcomSubtree(node: $0) }

        print("📦 [DraggedGedcomSubtree.init] Created transferable representation:")
                debugPrintSubtree(indent: "  ")
                print("------------------------------------------\n")
    }

    /// Creates a GedcomNode tree from a transferred version. The reverse operation of init.
    /// A method that takes a DraggedGedcomSubtree as its self argument.
    func toGedcomNode() -> GedcomNode {
        let newNode = GedcomNode(tag: tag, val: val)
        for child in children {
            newNode.addKid(child.toGedcomNode())
        }

        print("📥 [DraggedGedcomSubtree.toGedcomNode] Reconstructed GedcomNode tree:")
                newNode.debugPrintTree(prefix: "  ")
                print("------------------------------------------\n")


        return newNode
    }

    // MARK: - Debug helpers
        private func debugPrintSubtree(indent: String = "") {
            let valText = val ?? ""
            print("\(indent)\(tag) \(valText)")
            for child in children {
                child.debugPrintSubtree(indent: indent + "  ")
            }
        }
}

extension GedcomNode {
    func debugPrintTree(prefix: String = "") {
        self.printTree()
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool,
                                          transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}
