//
//  GedcomTreeView.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 22 September 2025.
//  Last changed on 26 November 2025.
//

import SwiftUI
import DeadEndsLib

struct GedcomTreeView: View {
    
    let root: Person
    @Binding var expandedNodes: Set<ObjectIdentifier>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                treeRow(for: root.root)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func treeRow(for node: GedcomNode) -> some View {
        let isExpandable = node.kid != nil
        let isExpanded = expandedNodes.contains(ObjectIdentifier(node))

        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                if isExpandable {
                    Button {
                        toggle(node)
                    } label: {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 16)
                } else {
                    Spacer().frame(width: 16)
                }

                Text("\(node.lev) \(node.tag) \(node.val ?? "")")
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, CGFloat(node.lev) * 16)

            if isExpanded {
                ForEach(children(of: node), id: \.uid) { child in
                    AnyView(treeRow(for: child))   // 👈 type-erasure here
                }
            }
        }
    }

    private func toggle(_ node: GedcomNode) {
        let id = ObjectIdentifier(node)
        if expandedNodes.contains(id) {
            expandedNodes.remove(id)
        } else {
            expandedNodes.insert(id)
        }
    }
}

private func children(of node: GedcomNode) -> [GedcomNode] {
    var result: [GedcomNode] = []
    var current = node.kid
    while let c = current {
        result.append(c)
        current = c.sib
    }
    return result
}
