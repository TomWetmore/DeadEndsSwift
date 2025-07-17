//
//  PersonActionBar.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 2 July 2025.
//  Last changed on 14 July 2025.
//

import SwiftUI
import DeadEndsLib

struct GedcomNodeList: Identifiable {
    let id = UUID()
    let nodes: [GedcomNode]
}

struct PersonActionBar: View {
    @EnvironmentObject var model: AppModel
    let person: GedcomNode
    @State private var familyList: GedcomNodeList? = nil
    @State private var showEditSheet = false

    var body: some View {
        HStack {
            Button("Father") {
                navigateToParent(sex: "M")
            }
            Button("Mother") {
                navigateToParent(sex: "F")
            }
            Button("Older Sibling") {
                navigateToSibling(offset: -1)
            }
            Button("Younger Sibling") {
                navigateToSibling(offset: +1)
            }
            Button("Pedigree") {
                model.path.append(Route.pedigree(person))
            }
            Button("Family") {
                guard let ri = model.database?.recordIndex else { return }
                let families = person.children(withTag: "FAMS").compactMap {
                    $0.value.flatMap { ri[$0] }
                }
                if families.count == 1 {
                    model.path.append(Route.family(families[0]))
                } else if families.count > 1 {
                    familyList = GedcomNodeList(nodes: families)
                } else {
                    model.status = "\(person.displayName) is not a spouse in any family."
                }
            }
            Button("Edit") {
                showEditSheet = true
            }
            .sheet(isPresented: $showEditSheet) {
                PersonEditView(person: person)
                    .environmentObject(model)
            }
        }
        .buttonStyle(.bordered)
        .font(.body)
        .tint(.secondary)
        .padding(.top)
        // Learn a little Swift. .sheet takes an optional. If nil nothing happens. If non-nil
        // the content closure is called. It takes the unwrapped item and returns a View.
        .sheet(item: $familyList) { wrapped in // shown if familyList is non-nil
            FamilySelectionSheet(families: wrapped.nodes) { selectedFamily in
                familyList = nil
                model.path.append(Route.family(selectedFamily))
            }
            .environmentObject(model)
        }
    }

    private func navigateToParent(sex: String) {
        guard let ri = model.database?.recordIndex else {
            model.status = "No database loaded"
            return
        }
        if let parent = person.resolveParent(sex: sex, recordIndex: ri) {
            model.path.append(Route.person(parent))
            model.status = nil
        } else {
            model.status = "No \(sex == "M" ? "father" : "mother") found"
        }
    }

    private func navigateToSibling(offset: Int) {
        guard let ri = model.database?.recordIndex else {
            model.status = "No database loaded"
            return
        }
        guard let famcKey = person.child(withTag: "FAMC")?.value,
              let family = ri[famcKey] else {
            model.status = "No family found"
            return
        }
        let siblings = family.children(withTag: "CHIL").compactMap { $0.value.flatMap { ri[$0] } }
        guard let index = siblings.firstIndex(of: person) else {
            model.status = "Could not locate person in siblings"
            return
        }

        let newIndex = index + offset
        guard siblings.indices.contains(newIndex) else {
            model.status = offset < 0 ? "No older sibling" : "No younger sibling"
            return
        }
        model.path.append(Route.person(siblings[newIndex]))
        model.status = nil
    }
}
