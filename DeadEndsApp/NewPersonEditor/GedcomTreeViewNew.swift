//
//  GedcomTreeViewNew.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 1 October 2025.
//  Last changed on 1 October 2025
//

import SwiftUI
import DeadEndsLib

struct GedcomTreeViewNew: View {
    @ObservedObject var viewModel: PersonEditorViewModelNew
    var node: GedcomNode

    var body: some View {
        if node.kids.isEmpty {
            GedcomRowNew(viewModel: viewModel, node: node)
        } else {
            DisclosureGroup(
                isExpanded: Binding(
                    get: { viewModel.expanded.contains(node.id) },
                    set: { isExpanded in
                        if isExpanded { viewModel.expanded.insert(node.id) }
                        else { viewModel.expanded.remove(node.id) }
                    }
                ),
                content: {
                    ForEach(node.kids, id: \.id) { child in
                        GedcomTreeViewNew(viewModel: viewModel, node: child)
                            .padding(.leading, 20)
                    }
                },
                label: {
                    GedcomRowNew(viewModel: viewModel, node: node)
                }
            )
        }
    }
}

/// Basic row with add/remove affordances.
struct GedcomRowNew: View {

    @ObservedObject var viewModel: PersonEditorViewModelNew
    var node: GedcomNode

    var body: some View {

        // HStack that shows an entire Gedcom line with level, key (if root), editable tag and editable value.
        // Also show 'affordances'.
        HStack {
            // Level indicator
            Text("\(String(describing: node.lev))")
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)

            // Show key only if root
            if let key = node.key {
                Text("\(key)")
                    .foregroundColor(.blue)
                    .font(.system(.body, design: .monospaced))
            }
            // Show the tag.
            TextField("TAG", text: Binding(
                get: { node.tag },
                set: { viewModel.updateTag(for: node, newTag: $0) }
            ))
            .frame(width: 80)
            // Show the value if not nil.
            TextField("Value", text: Binding(
                get: { node.val ?? "" },
                set: { viewModel.updateValue(for: node, newValue: $0) }
            ))

            Spacer()

            // Control to add a new last child to the selected node.
            Button {
                viewModel.addChild(to: node)
            } label: {
                Image(systemName: "plus.circle").foregroundColor(.green)
            }
            .buttonStyle(.plain)
            // Control to add a new next sibling to the selected node.
            Button {
                viewModel.addSibling(to: node)
            } label : {
                Image(systemName: "plus.square").foregroundColor(.green)
            }

            // Control to remove the selected node.
            Button {
                viewModel.remove(node)
            } label: {
                Image(systemName: "trash").foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
    }
}
