//
//  PedigreeActionBar.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 14 January 2026.
//  Last changed on 14 January 2026.
//

import SwiftUI
import DeadEndsLib

/// Action buttons shown on a pedigree page.
struct PedigreeActionBar: View {

    @EnvironmentObject var model: AppModel
    @State private var childList: PersonList?
    @State private var spouseList: PersonList?

    let person: Person
    private var indexOrNil: RecordIndex? { model.database?.recordIndex }

    var body: some View {
        HStack {
            Button("Father") { gotoFather() }.disabled(!hasFather)
            Button("Mother") { gotoMother() }.disabled(!hasMother)
            Button("Child") { gotoChild() }.disabled(!hasChild)
            Button("Spouse") { gotoSpouse() }.disabled(!hasSpouse)
        }
        .sheet(item: $childList) { list in
            PersonSelectionSheet(title: list.title, persons: list.persons) { selected in
                childList = nil
                model.path.append(Route.pedigree(selected)) // or Route.person(selected)
            }
            .environmentObject(model)
        }

        .sheet(item: $spouseList) { list in
            PersonSelectionSheet(title: list.title, persons: list.persons) { selected in
                spouseList = nil
                model.path.append(Route.pedigree(selected))
            }
            .environmentObject(model)
        }
    }

    private func requireIndex() -> RecordIndex? {
        guard let index = indexOrNil else {
            model.status = "No database loaded"
            return nil
        }
        return index
    }

    /// Find father; go to him in the pedigree.
    private func gotoFather() {
        
        guard let index = requireIndex() else { return }
        guard let father = person.father(in: index) else {
            model.status = "Father unknown"
            return
        }
        model.status = nil
        model.path.append(Route.pedigree(father))
    }

    /// Find mother; go to her in the pedigree.
    private func gotoMother() {

        guard let index = requireIndex() else { return }
        guard let mother = person.mother(in: index) else {
            model.status = "Mother unknown"
            return
        }
        model.status = nil
        model.path.append(Route.pedigree(mother))
    }

    private func gotoChild() {

        guard let index = requireIndex() else { return }
        let children = person.children(in: index)
        if children.count == 1 {
            model.path.append(Route.pedigree(children[0]))
        } else if children.count > 1 {
            childList = PersonList(title: "Select Child", persons: children)
        } else {
            model.status = "\(person.displayName()) has no children in any family."
        }
    }

    private func gotoSpouse() {

        guard let index = requireIndex() else { return }
        let spouses = person.spouses(in: index)
        if spouses.count == 1 {
            model.path.append(Route.pedigree(spouses[0]))
        } else if spouses.count > 1 {
            spouseList = PersonList(title: "Select Spouse", persons: spouses)
        } else {
            model.status = "\(person.displayName()) is not a spouse in any family."
        }
    }

    private var hasFather: Bool {
        guard let index = indexOrNil else { return false }
        return person.father(in: index) != nil
    }

    private var hasMother: Bool {
        guard let index = indexOrNil else { return false }
        return person.mother(in: index) != nil
    }

    private var hasChild: Bool {
        guard let index = indexOrNil else { return false }
        return !person.children(in: index).isEmpty
    }

    private var hasSpouse: Bool {
        guard let index = indexOrNil else { return false }
        return !person.spouses(in: index).isEmpty
    }
}
