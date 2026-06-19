//
//  PedigreeActionBar.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 14 January 2026.
//  Last changed on 19 June 2026.
//

import SwiftUI
import DeadEndsLib

/// Action buttons shown on a pedigree page.
struct PedigreeActionBar: View {

    @Environment(AppModel.self) var model
    @State private var personList: PersonSelectRequest?

    let person: Person
    private var indexOrNil: RecordIndex? { model.database?.recordIndex }

    /// Render the pedigree pedigree action bar.
    var body: some View {
        HStack {
            Button("Father") { gotoFather() }.disabled(!hasFather)
            Button("Mother") { gotoMother() }.disabled(!hasMother)
            Button("Child") { gotoChild() }.disabled(!hasChild)
            Button("Spouse") { gotoSpouse() }.disabled(!hasSpouse)
        }
        .sheet(item: $personList) { list in
            PersonSelectionSheet(title: list.title, persons: list.persons) { selected in
                personList = nil
                model.path.append(Route.pedigree(selected)) // or Route.person(selected)
            }
            .environment(model)
        }
    }

    /// Require an index to continue.
    private func requireIndex() -> RecordIndex? {
        guard let index = indexOrNil else {
            model.status = "No database loaded"
            return nil
        }
        return index
    }

    /// Go to the father on the pedigree page.
    private func gotoFather() {
        
        guard let index = requireIndex() else { return }
        guard let father = person.father(in: index) else {
            model.status = "Father unknown"
            return
        }
        model.status = nil
        model.path.append(Route.pedigree(father))
    }

    /// Go to the mother on the pedigree page.
    private func gotoMother() {

        guard let index = requireIndex() else { return }
        guard let mother = person.mother(in: index) else {
            model.status = "Mother unknown"
            return
        }
        model.status = nil
        model.path.append(Route.pedigree(mother))
    }

    /// Go to a child on the pedigree page.
    private func gotoChild() {
        guard let index = requireIndex() else { return }
        let children = person.children(in: index)
        if children.count == 1 {
            model.path.append(Route.pedigree(children[0]))
        } else if children.count > 1 {
            personList = PersonSelectRequest(title: "Select Child", persons: children)
        } else {
            model.status = "\(person.displayName()) has no children in any family."
        }
    }

    /// Go to a spouse on the pedigree page.
    private func gotoSpouse() {
        guard let index = requireIndex() else { return }
        let spouses = person.spouses(in: index)
        if spouses.count == 1 {
            model.path.append(Route.pedigree(spouses[0]))
        } else if spouses.count > 1 {
            personList = PersonSelectRequest(title: "Select Spouse", persons: spouses)
        } else {
            model.status = "\(person.displayName()) is not a spouse in any family."
        }
    }

    /// See if a person has a father.
    private var hasFather: Bool {
        guard let index = indexOrNil else { return false }
        return person.father(in: index) != nil
    }

    /// See if a person has a mother.
    private var hasMother: Bool {
        guard let index = indexOrNil else { return false }
        return person.mother(in: index) != nil
    }

    /// See if a person has children.
    private var hasChild: Bool {
        guard let index = indexOrNil else { return false }
        return !person.children(in: index).isEmpty
    }

    /// See if a person has spouses.
    private var hasSpouse: Bool {
        guard let index = indexOrNil else { return false }
        return !person.spouses(in: index).isEmpty
    }
}
