//
//  DescendantsView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 7 August 2025.
//  Last changed on 18 September 2025.
//

import SwiftUI
import DeadEndsLib

/// A lightweight structure for building a descendant display tree.
/// It wraps a `GedcomNode` for the person and precomputes the person's children.
struct DescendantNode: Identifiable {
    let person: Person
    let children: [DescendantNode]
    var id: String { person.key }
}

struct DescendantsView: View {
    @EnvironmentObject var model: AppModel
    let root: Person

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

    private func buildTree(from person: Person) -> DescendantNode {
        let index = model.database?.recordIndex ?? [:]
        func rec(_ person: Person) -> DescendantNode {
            let families = person.kids(withTag: "FAMS")
                .compactMap { $0.val }
                .compactMap { index.family(for: $0) }
            let children = families.flatMap { family in
                family.kids(withTag: "CHIL")
                    .compactMap { $0.val }
                    .compactMap { index.person(for: $0) }
            }
            return DescendantNode(
                person: person,
                children: children.map(rec)
            )
        }
        return rec(person)
    }

    private func preexpandFirstTwoLevels(from person: Person) {
        let index = model.database?.recordIndex ?? [:]
        func walk(_ person: Person, depth: Int) {
            let id = person.key
            if depth <= 1 { expanded.insert(id) }
            let families = person.kids(withTag: "FAMS").compactMap { $0.val.flatMap { index.family(for: $0) } }
            let kids = families.flatMap { family in
                family.kids(withTag: "CHIL").compactMap { $0.val.flatMap { index.person(for: $0) } }
            }
            kids.forEach { walk($0, depth: depth + 1) }
        }
        walk(person, depth: 0)
    }
}

struct TreeRow<RowContent: View>: View {
    let node: DescendantNode
    @Binding var expanded: Set<String>
    let row: (Person) -> RowContent

    var body: some View {
        let key = node.person.key

        DisclosureGroup(
            isExpanded: Binding(
                get: { expanded.contains(key) },
                set: { isOpen in
                    if isOpen { expanded.insert(key) } else { expanded.remove(key) }
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
