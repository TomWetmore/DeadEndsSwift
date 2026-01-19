//
//  PersonActionBar.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 2 July 2025.
//  Last changed on 11 January 2026.
//

import SwiftUI
import DeadEndsLib

struct FamilyList: Identifiable {
    let id = UUID()
    let nodes: [Family]
}

/// Row of action buttons displayed on PersonPage views.

struct PersonActionBar: View {

    @EnvironmentObject var model: AppModel
    let person: Person
    @State private var familyList: FamilyList? = nil
    @State private var showEditSheet = false
    @State private var showingDescList = false

    /// Row of action buttons.
    var body: some View {

        HStack {
            Button("Father") {
                navigateToParent(sex: "M")
            }
            Button("Mother") {
                navigateToParent(sex: "F")
            }
            Button("Older Sibling") {
                navigateToNextSibling()
            }
            Button("Younger Sibling") {
                navigateToPreviousSibling()
            }
            Button("Pedigree") {
                model.path.append(Route.pedigree(person))
            }
            Button("Descendants") {
                model.path.append(Route.descendants(person))
            }
            Button("Family") {
                guard let index = model.database?.recordIndex else { return }
                let families = person.kids(withTag: "FAMS").compactMap {
                    $0.val.flatMap { index.family(for: $0) }
                }
                if families.count == 1 {
                    model.path.append(Route.family(families[0]))
                } else if families.count > 1 {
                    familyList = FamilyList(nodes: families)
                } else {
                    model.status = "\(String(describing: person.displayName)) is not a spouse in any family."
                }
            }
            Button("Family Tree") {
                model.path.append(Route.familyTree(person))
            }
//            Button("Tidy Test") {
//                guard let index = model.database?.recordIndex else { return }
//                tidyTest(person: person, index: index);
//            }
            Button("Descendancy List") {
                model.path.append(Route.descendancy(person))
            }
            Button("New Person") {
                guard let index = model.database?.recordIndex,
                      let newPerson = Person(GedcomNode(key: generateRandomKey(index: index), tag: "INDI"))
                else { return }
                model.path.append(Route.personEditor(newPerson))
            }
            Button("Tree Editor") {
                // assuming you're inside a PersonView and have `person`
                model.path.append(Route.gedcomTreeEditor(person))
            }
//            Button("New Edit") {
//                model.path.append(Route.personEditor(person))
//            }
//            Button("Newer Edit") {
//                model.path.append(Route.personEditorNew(person))
//            }

            Button("Open Desktop") {
                print("Button tapped")
                model.path.append(Route.desktop(person))
                print("Appended .desktop route")
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
        if let parent = person.resolveParent(sex: sex, index: ri) {
            model.path.append(Route.person(parent))
            model.status = nil
        } else {
            model.status = "No \(sex == "M" ? "father" : "mother") found"
        }
    }

    /// Navigate to the older sibling of current person.
    private func navigateToNextSibling() {
        guard let index = model.database?.recordIndex else {
            model.status = "No database found"
            return
        }
        guard let sibling = person.nextSibling(in: index) else {
            model.status = "No older sibling"
            return
        }
        model.path.append(Route.person(sibling))
        model.status = nil
    }

    /// Navigate to the younger sibling of the current person.
    private func navigateToPreviousSibling() {
        guard let index = model.database?.recordIndex else {
            model.status = "No database found"
            return
        }
        guard let sibling = person.previousSibling(in: index) else {
            model.status = "No younger sibling"
            return
        }
        model.path.append(Route.person(sibling))
        model.status = nil
    }
}

private func tidyTest(person: Person, index: RecordIndex) {

    guard let uniontree = buildDescendantsTree(from: person, index: index, depth: 3)
            else { return }
    showDescendantsTree(uniontree, index: index)

}

/// Generate a random Record key.

func generateRandomKey(index: RecordIndex) -> String {

    let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")

    for _ in 0..<10 {
        let randomChars = (0..<6).map { _ in alphabet.randomElement()! }
        let key = "@I" + String(randomChars) + "@"
        if index[key] == nil {
            return key
        }
    }
    fatalError("Unable to generate unique Record key.")
}
