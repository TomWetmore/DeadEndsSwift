//
//  GedcomTreeEditorRow.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 8 October 2025.
//  Last changed on 6 March 2026.

/// GedcomTreeEditorRow is the view that renders each row in a Gedcom
/// tree editor. It handles the indent, chevron, level, key, tag, and
/// value fields of the row

import SwiftUI
import DeadEndsLib

/// View that renders a single row within a Gedcom tree view.
struct GedcomTreeEditorRow: View {
    @Bindable var viewModel: GedcomTreeEditorModel
    let treeManager: GedcomTreeManager
    var node: GedcomNode

    // Focus Tracking
    enum Field: Hashable {
        case tag(UUID)
        case val(UUID)
    }
    @FocusState private var focusedField: Field?
    @State private var originalTag: String = ""
    @State private var originalVal: String? = nil
    @State private var editTag: String = ""
    @State private var editVal: String = ""

    /// Render a row of the Gedcom edit tree. This view is recursive; it
    /// first renders the row for the provided root argument and then renders
    /// the children of the root.
    var body: some View {
        let _ = viewModel.changeCounter

        return VStack(spacing: 0) {
            rowContent
                .onTapGesture {
                    focusedField = nil
                    viewModel.selectedNode = node
                }
            if viewModel.expandedSet.contains(node.id) {
                ForEach(node.kids) { kid in  // Recurse to children.
                    GedcomTreeEditorRow(viewModel: viewModel, treeManager: treeManager, node:kid)
                }
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        viewModel.rowFrames[node.id] =
                        geo.frame(in: .named("gedcomTree"))
                    }
                    .onChange(of: geo.frame(in: .named("gedcomTree"))) { _, newFrame in
                        viewModel.rowFrames[node.id] = newFrame
                    }
                    .onDisappear {
                        viewModel.rowFrames.removeValue(forKey: node.id)
                    }
            }
        )
        .onAppear {
            if focusedField != .tag(node.id) { editTag = node.tag }
            if focusedField != .val(node.id) { editVal = node.val ?? "" }
        }
        .onChange(of: viewModel.changeCounter) { _, _ in
            if focusedField != .tag(node.id) { editTag = node.tag }
            if focusedField != .val(node.id) { editVal = node.val ?? "" }
        }
        .onChange(of: viewModel.selectedNode?.id) { _, _ in
            focusedField = nil
        }
    }

    /// Computed property that returns the Gedcom row content View.
    private var rowContent: some View {
        HStack {
            chevronView
            levelView
            keyView
            tagField
            valueField
            Spacer()
        }
        .padding(.leading, CGFloat(node.lev) * 32)  // Indent.
        .contentShape(Rectangle())
        .monospaced()
        .padding(.horizontal, 10)
        .padding(.vertical, 2)
        .background(
            viewModel.selectedNode === node
            ? Color.accentColor.opacity(0.2)
            : Color.clear
        )
    }

    /// Render chevron.
    private var chevronView: some View {
        Group {
            if node.hasKids {
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
                Image(systemName: "chevron.right")
                    .opacity(0)  // Make chevron invisible.
                    .frame(width: 16)
            }
        }
    }

    /// Render level,
    private var levelView: some View {
        Text("\(node.lev)").frame(width: 20)
    }

    /// Render key on root nodes.
    private var keyView: some View {
        Group {
            if let key = node.key {
                Text(key)
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
    }

    /// Render tag field.
    private var tagField: some View {
        TextField("", text: $editTag)
            .frame(width: 80)
            .textFieldStyle(.plain)
            .focused($focusedField, equals: .tag(node.id))
            .onSubmit {
                focusedField = nil
            }
            .allowsHitTesting(viewModel.selectedNode === node)
            .onChange(of: focusedField) { oldFocus, newFocus in
                if newFocus == .tag(node.id) {  // Focus gained.
                    originalTag = node.tag
                    editTag = node.tag
                    return
                }
                if oldFocus == .tag(node.id) {  // Focus lost.
                    if editTag != originalTag {
                        treeManager.editTag(node, from: originalTag, to: editTag)
                    }
                }
            }
            .onDisappear {  // Field can vanish with focus transition.
                if focusedField == .tag(node.id) {
                    commitTagIfNeeded()
                }
            }
    }

    /// Render value field.
    private var valueField: some View {
        ZStack(alignment: .leading) {
            if editVal.isEmpty,  // Add summary date & place text to closed event node.
               !viewModel.expandedSet.contains(node.id),
               let summary = eventSummary(for: node) {
                Text(summary)
                    .italic()
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
            TextField("", text: $editVal)
                .textFieldStyle(.plain)
                .focused($focusedField, equals: .val(node.id))
                .allowsHitTesting(viewModel.selectedNode === node)
                .onChange(of: focusedField) { oldFocus, newFocus in
                    if newFocus == .val(node.id) {  // Focus gained.
                        originalVal = node.val
                        editVal = node.val ?? ""
                        return
                    }
                    if oldFocus == .val(node.id) {  // Focus lost.
                        let trimmed = editVal.trimmingCharacters(in: .whitespacesAndNewlines)
                        let newVal: String? = trimmed.isEmpty ? nil : trimmed
                        if newVal != originalVal {
                            treeManager.editVal(node, from: originalVal, to: newVal)
                        }
                    }
                }
                .onDisappear {  // Field can vanish without focus transition.
                    if focusedField == .val(node.id) {
                        commitValIfNeeded()
                    }
                }
        }
    }

    private func commitTagIfNeeded() {
        let newTag = editTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard newTag != originalTag else { return }
        treeManager.editTag(node, from: originalTag, to: newTag)
        originalTag = newTag
    }

    private func commitValIfNeeded() {
        let trimmed = editVal.trimmingCharacters(in: .whitespacesAndNewlines)
        let newVal: String? = trimmed.isEmpty ? nil : trimmed
        guard newVal != originalVal else { return }
        treeManager.editVal(node, from: originalVal, to: newVal)
        originalVal = newVal
    }
}

/// Build event summary for a top-level event node.
func eventSummary(for node: GedcomNode) -> String? {
    guard node.val == nil else { return nil }
    switch node.tag {
    case "BIRT", "DEAT", "MARR", "CHR", "BAPM", "BCHL", "RESI", "LAND", "EDU", "OCCU", "GRAD":
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

/// Used in debug statements to show nil and empty strings as nil and "".
func pval(_ s: String?) -> String {
    if s == nil { return "nil" }
    else if s == "" { return "\"\"" }
    else { return s! }
}
