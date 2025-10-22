//
//  PersonActionBar.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 2 July 2025.
//  Last changed on 2 October 2025.
//

import SwiftUI
import DeadEndsLib

struct GedcomNodeList: Identifiable {  // TODO: DEPRECATED
    let id = UUID()
    let nodes: [GedcomNode]
}

struct FamilyList: Identifiable {
    let id = UUID()
    let nodes: [Family]
}

struct PersonActionBar: View {
    @EnvironmentObject var model: AppModel
    let person: Person
    @State private var familyList: FamilyList? = nil
    @State private var showEditSheet = false
    @State private var showingDescList = false


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
            Button("Descendants") {
                model.path.append(Route.descendants(person))
            }
            Button("Family") {
                guard let ri = model.database?.recordIndex else { return }
                let families = person.kids(withTag: "FAMS").compactMap {
                    $0.val.flatMap { ri.family(for: $0) }
                }
                if families.count == 1 {
                    model.path.append(Route.family(families[0]))
                } else if families.count > 1 {
                    familyList = FamilyList(nodes: families)
                } else {
                    model.status = "\(person.displayName) is not a spouse in any family."
                }
            }
            Button("Family Tree") {
                model.path.append(Route.familyTree(person))
            }
            Button("Tidy Test") {
                guard let index = model.database?.recordIndex else { return }
                tidyTest(person: person, index: index);
            }
            Button("Descendancy List") {
                model.path.append(Route.descendancy(person))
            }
            Button("New Person") {
                let newPerson = Person(GedcomNode(key: generateRandomKey(), tag: "INDI"))
                model.path.append(Route.personEditor(newPerson!))
            }
            Button("Tree Editor") {
                // assuming you're inside a PersonView and have `person`
                model.path.append(Route.gedcomTreeEditor(person))
            }
            Button("New Edit") {
                model.path.append(Route.personEditor(person))
            }
            Button("Newer Edit") {
                model.path.append(Route.personEditorNew(person))
            }
            Button("Edit") {
                showEditSheet = true
            }
            .sheet(isPresented: $showEditSheet) {
                PersonEditSheet(person: person)
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

    /// Navigates to a sibling.
    private func navigateToSibling(offset: Int) {
        guard let rindex = model.database?.recordIndex else {
            model.status = "No database loaded"
            return
        }
        guard let famcKey = person.kid(withTag: "FAMC")?.val,
              let family = rindex.family(for: famcKey) else {
            model.status = "No family found"
            return
        }
        let siblings = family.kids(withTag: "CHIL").compactMap { $0.val.flatMap { rindex.person(for: $0) } }
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

private func tidyTest(person: Person, index: RecordIndex) {
    guard let uniontree = buildDescendantsTree(from: person, index: index, depth: 3)
            else { return }
    showDescendantsTree(uniontree, index: index)

}

func generateRandomKey() -> String {
    let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let randomChars = (0..<6).compactMap { _ in alphabet.randomElement() }
    return "@I" + String(randomChars) + "@"
}
