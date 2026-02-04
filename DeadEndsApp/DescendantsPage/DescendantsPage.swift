//
//  DescendantsPage.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 7 August 2025.
//  Last changed on 2 February 2026.
//

import SwiftUI
import DeadEndsLib

/// Descendant tree node.
struct DescendantNode: Identifiable {
    let id = UUID()
    let person: Person
    let children: [DescendantNode]
}

/// Descendants page view.
struct DescendantsPage: View {

    @State private var expanded: Set<DescendantNode.ID> = []  // Expanded nodes.
    @EnvironmentObject var model: AppModel
    @State private var rootNode: DescendantNode? = nil  // Descendant tree.
    let root: Person

    private var index: RecordIndex? { model.database?.recordIndex }

    /// Render descendants page view.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                if let rootNode {
                    TreeRow(node: rootNode, expanded: $expanded) { person in
                        PersonTile(person: person)
                            .onTapGesture { model.path.append(Route.person(person)) }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Descendants")
        .task(id: root.key) {
            let tree = buildTree(from: root)
            rootNode = tree
            expanded.removeAll()
            expandFirstTwoLevels(from: tree)
        }
    }

    /// Build descendant tree and return root; guard against cycles.
    private func buildTree(from person: Person) -> DescendantNode {
        let index = index ?? [:]

        /// Recursive helper.
        func rec(_ person: Person, path: Set<RecordKey>) -> DescendantNode {
            if path.contains(person.key) {  // Seen before?
                return DescendantNode(person: person, children: [])
            }
            let newPath = path.union([person.key])
            let children = person.children(in: index)
            let childNodes = children.map { rec($0, path: newPath) }
            return DescendantNode(person: person, children: childNodes)
        }

        return rec(person, path: [])
    }

    /// Add children and grandchildren to expanded set.
    private func expandFirstTwoLevels(from node: DescendantNode) {
        func walk(_ node: DescendantNode, depth: Int) {
            if depth <= 1 { expanded.insert(node.id) }
            guard depth < 1 else { return }
            node.children.forEach { walk($0, depth: depth + 1) }
        }
        walk(node, depth: 0)
    }
}

/// Tree row view.
struct TreeRow<RowContent: View>: View {
    
    let node: DescendantNode
    @Binding var expanded: Set<DescendantNode.ID>
    let row: (Person) -> RowContent

    /// Render a tree row view with its descendant row views.
    var body: some View {
        let id = node.id

        if node.children.isEmpty {
            row(node.person)
        } else {
            DisclosureGroup(
                isExpanded: Binding(
                    get: { expanded.contains(id) },
                    set: { isOpen in
                        if isOpen { expanded.insert(id) } else { expanded.remove(id) }
                    }
                )
            ) {
                ForEach(node.children) { child in
                    TreeRow(node: child, expanded: $expanded, row: row)
                        .padding(.leading, 60)
                }
            } label: {
                row(node.person)
            }
        }
    }
}
