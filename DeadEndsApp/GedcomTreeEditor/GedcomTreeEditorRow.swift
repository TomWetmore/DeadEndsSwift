//
//  GedcomTreeEditorRow.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 8 October 2025.
//  Last changed on 4 January 2026.
//

import SwiftUI
import DeadEndsLib

struct GedcomTreeEditorRow: View {
    
    @Bindable var viewModel: GedcomTreeEditorModel

    let treeManager: GedcomTreeManager
    var node: GedcomNode

    // Focus Tracking
    enum Field: Hashable {
        case tag(UUID)
        case val(UUID)
    }
    // Holds the field (tag, val, nil) with focus.
    @FocusState private var focusedField: Field?
    
    // Original tag/val values during editing
    @State private var originalTag: String = ""
    @State private var originalVal: String = ""
    
    @State private var editTag: String = ""
    @State private var editVal: String = ""
    
    var body: some View {
        
        let _ = viewModel.textCounter   // Force dependency.
        print("Render node:", node.tag, ObjectIdentifier(node))  // Debug.
        
        return VStack(spacing: 0) {
            
            rowContent
                .onTapGesture {
                    focusedField = nil
                    viewModel.selectedNode = node
                }
            
            if viewModel.expandedSet.contains(node.id) {
                ForEach(node.kids) { kid in
                    GedcomTreeEditorRow(viewModel: viewModel, treeManager: treeManager, node:kid)
                }
            }
        }
        .onAppear {
            editTag = node.tag
            editVal = node.val ?? ""
        }
        .onChange(of: viewModel.textCounter) { _, _ in
            editTag = node.tag
            editVal = node.val ?? ""
        }
        .onChange(of: viewModel.selectedNode?.id) { _, _ in
            focusedField = nil
        }
    }
    
    /// Computed property that returns the row content View.
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
    }
    
    /// Indent.

    private var indentView: some View {
        
        ForEach(0..<node.lev, id: \.self) { _ in
            Spacer().frame(width: 32)
        }
    }
    
    /// Chevron (visible or invisible).
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
                Image(systemName: "chevron.right")  // Pretend it's there for spacing,
                    .opacity(0)  // by making it invisible.
                    .frame(width: 16)
            }
        }
    }
    
    /// Level.

    private var levelView: some View {

        Text("\(node.lev)").frame(width: 20)
    }
    
    /// Key (on root nodes).

    private var keyView: some View {
        
        Group {
            if let key = node.key {
                Text(key)
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
    }
    
    /// Tag.

    private var tagField: some View {
        
        TextField("", text: $editTag)
            .frame(width: 80)
            .textFieldStyle(.plain)
            .focused($focusedField, equals: .tag(node.id))
            .onSubmit {
                focusedField = nil    // Clears focus.
            }
            .allowsHitTesting(viewModel.selectedNode === node)
            .onAppear {
                // When the row appears, seed local edit buffer from the node.
                editTag = node.tag
            }
            .onChange(of: focusedField) { oldFocus, newFocus in
                if newFocus == .tag(node.id) {  // Focus gained.
                    print("Focus gained")  // Debug.
                    originalTag = node.tag   // store model’s tag
                    editTag     = node.tag   // sync UI to model
                    return
                }
                if oldFocus == .tag(node.id) {  // Focus lost.
                    print("Focus lost")
                    if editTag != originalTag {
                        print("Tag changed from \(originalTag) → \(editTag)")
                        treeManager.editTag(node, from: originalTag, to: editTag)
                    } else {
                        print("Tag unchanged.")
                    }
                }
            }
        
    }

    /// Value.

    private var valueField: some View {
        
        ZStack(alignment: .leading) {
            
            // Summary text when no value and collapsed.
            if editVal.isEmpty,
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
                        originalVal = node.val ?? ""
                        editVal = node.val ?? ""     // Sync UI with model.
                        return
                    }
                    if oldFocus == .val(node.id) {  // Focus lost.
                        if editVal != originalVal {
                            print("Value changed from \(originalVal) to \(editVal)")  // Debug.
                            treeManager.editVal(node, from: originalVal, to: editVal)
                        } else {
                            print("Value unchanged.")  // Debug.
                        }
                    }
                }
        }
    }
}

/// Build event summary for a top-level event node.

func eventSummary(for node: GedcomNode) -> String? {

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

