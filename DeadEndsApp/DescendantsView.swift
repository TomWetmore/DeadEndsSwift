//
//  DescendantsView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 7 August 2025.
//  Last changed on 7 August 2025.
//

import SwiftUI
import DeadEndsLib

/// A lightweight structure for building a descendant display tree.
/// It wraps a `GedcomNode` for the person and precomputes the person's children.
struct DescendantNode: Identifiable {
    let person: GedcomNode
    let children: [DescendantNode]
    var id: String { person.key ?? UUID().uuidString }
}

struct DescendantsView: View {
    @EnvironmentObject var model: AppModel
    let root: GedcomNode

    @State private var expanded: Set<String> = []   // which nodes are open

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                TreeRow(
                    node: buildTree(from: root),
                    expanded: $expanded
                ) { person in
                    PersonRow(person: person, isInteractive: true)
                        .onTapGesture { model.path.append(Route.person(person)) }
                }
            }
            .padding()
        }
        .navigationTitle("Descendants")
        .onAppear {
            // Optional: pre-open first two levels
            preexpandFirstTwoLevels(from: root)
        }
    }

    private func buildTree(from person: GedcomNode) -> DescendantNode {
        let ri = model.database?.recordIndex ?? [:]
        func rec(_ p: GedcomNode) -> DescendantNode {
            let fams = p.children(withTag: "FAMS")
                .compactMap { $0.value }
                .compactMap { ri[$0] }
            let kids = fams.flatMap { fam in
                fam.children(withTag: "CHIL")
                    .compactMap { $0.value }
                    .compactMap { ri[$0] }
            }
            return DescendantNode(
                person: p,
                children: kids.map(rec)
            )
        }
        return rec(person)
    }

    private func preexpandFirstTwoLevels(from person: GedcomNode) {
        let ri = model.database?.recordIndex ?? [:]
        func walk(_ p: GedcomNode, depth: Int) {
            guard let id = p.key else { return }
            if depth <= 1 { expanded.insert(id) } // open root + children
            let fams = p.children(withTag: "FAMS").compactMap { $0.value.flatMap { ri[$0] } }
            let kids = fams.flatMap { fam in
                fam.children(withTag: "CHIL").compactMap { $0.value.flatMap { ri[$0] } }
            }
            kids.forEach { walk($0, depth: depth + 1) }
        }
        walk(person, depth: 0)
    }
}

struct TreeRow<RowContent: View>: View {
    let node: DescendantNode
    @Binding var expanded: Set<String>
    let row: (GedcomNode) -> RowContent

    var body: some View {
        let key = node.person.key

        DisclosureGroup(
            isExpanded: Binding(
                get: { key.map { expanded.contains($0) } ?? false },
                set: { isOpen in
                    guard let k = key else { return }
                    if isOpen { expanded.insert(k) } else { expanded.remove(k) }
                }
            )
        ) {
            ForEach(node.children) { child in
                TreeRow(node: child, expanded: $expanded, row: row)
                    .padding(.leading, 20)
            }
        } label: {
            row(node.person)
        }
    }
}
