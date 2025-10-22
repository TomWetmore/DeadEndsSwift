//
//  GedcomTreeEditorRow.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 8 October 2025.
//  Last changed on 20 October 2025.

import SwiftUI
import DeadEndsLib

struct GedcomTreeEditorRow: View {
    
    @ObservedObject var node: GedcomNode
    @ObservedObject var viewModel: GedcomTreeEditorModel
    let treeManager: GedcomTreeManager

    // Focus Tracking
    enum Field: Hashable {
        case tag(UUID)
        case val(UUID)
    }
    // Holds the field (tag, val or nil) that currently has focus.
    @FocusState private var focusedField: Field?

    // Original tag/val values during editing
    @State private var originalTag: String = ""
    @State private var originalVal: String = ""

    var body: some View {
        VStack(spacing: 0) {

            rowContent
            if viewModel.expandedSet.contains(node.id) {
                ForEach(node.kids) { kid in
                    GedcomTreeEditorRow(node: kid, viewModel: viewModel, treeManager: treeManager)
                }
            }
        }
    }

    private var rowContent: some View {
        HStack {
            indentView
            chevronView
            levelView
            keyView
            tagField
            valueField
            Spacer()
        }
        .contentShape(Rectangle())
        .monospaced()
        .padding(.horizontal, 10)
        .padding(.vertical, 2)
        .background(
            viewModel.selectedNode === node
            ? Color.accentColor.opacity(0.2)
            : Color.clear
        )
        .onTapGesture {
            viewModel.selectedNode = node
        }
    }

    /// Adds indentation based on the node's level.
    private var indentView: some View {
        ForEach(0..<node.lev, id: \.self) { _ in
            Spacer().frame(width: 32)
        }
    }

    /// Adds visible or invisible chevron before the rest of the row.
    private var chevronView: some View {
        Group {
            if node.hasKids() {
                Button {
                    viewModel.toggleExpansion(for: node)
                } label: {
                    Image(systemName: viewModel.expandedSet.contains(node.id)
                          ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .frame(width: 16)
            } else {
                Image(systemName: "chevron.right")  // Pretend it there for spacing,
                    .opacity(0)  // but make it invisible.
                    .frame(width: 16)
            }
        }
    }

    /// Adds the level of the node to the row; not editable.
    private var levelView: some View {
        Text("\(node.lev)")
            .frame(width: 20)
    }

    /// Adds the key of this node to the row, only on root nodes; not editable.
    private var keyView: some View {
        Group {
            if let key = node.key {
                Text(key)
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
    }

    /// Tag field; editable in many cases.
    private var tagField: some View {
        TextField("", text: $node.tag)
            .frame(width: 80)
            .textFieldStyle(.plain)
            .focused($focusedField, equals: .tag(node.id))
            .onChange(of: focusedField) { newFocus in
                if newFocus == .tag(node.id) {
                    originalTag = node.tag
                    print("node.tag = \(node.tag)")
                } else if originalTag != node.tag {
                    //viewModel.manager.perform(.editTag(node, originalTag, node.tag))
                    print("Tag changed from \(originalTag) to \(node.tag)")
                }
            }
    }

    private var valueField: some View {
        ZStack(alignment: .leading) {
            if (node.val ?? "").isEmpty,
               let summary = eventSummary(for: node),
               !viewModel.expandedSet.contains(node.id) {
                Text(summary)
                    .italic()
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }

            TextField("", text: $node.val.bound)
                .textFieldStyle(.plain)
                .focused($focusedField, equals: .val(node.id))
                .onChange(of: focusedField) { newFocus in
                    if newFocus == .val(node.id) {
                        // Focus gained — store the original value
                        originalVal = node.val ?? ""
                        print("Focus IN → valueField: originalVal = \(originalVal)")
                    } else if focusedField == .val(node.id) {
                        // Focus lost — compare
                        let newVal = node.val ?? ""
                        if newVal != originalVal {
                            print("Value changed from \(originalVal) to \(newVal)")
                            //viewModel.manager.perform(.editVal(node, originalVal, newVal))
                        } else {
                            print("Focus OUT → valueField, but value unchanged.")
                        }
                    }
                }
        }
    }
}

/// Build an event summary if this is a top-level event node.
private func eventSummary(for node: GedcomNode) -> String? {
    //guard !expanded else { return nil }  // suppress if expanded
    // Only event-style nodes with no value
    guard node.val == nil else { return nil }
    switch node.tag {
    case "BIRT", "DEAT", "MARR", "CHR", "BAPM", "BCHL", "RESI", "LAND", "EDU", "OCCU": // add other events you like
        let date = node.kid(withTag: "DATE")?.val
        let place = node.kid(withTag: "PLAC")?.val
        var parts: [String] = []
        if let d = date, !d.isEmpty { parts.append(d) }
        if let p = place, !p.isEmpty { parts.append(p) }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    default:
        return nil
    }
}

