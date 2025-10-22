//
//  RootView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 24 June 2025.
//  Last changed on 12 October 2025.
//

import SwiftUI
import DeadEndsLib

/// Enumeration of values pushed onto the DeadEndsApp NavigationStack.
enum Route: Hashable {
    case person(Person)
    case pedigree(Person)
    case family(Family)
    case descendants(Person)
    case familyTree(Person)
    case descendancy(Person)
    case personEditor(Person)
    case personEditorNew(Person)
    case gedcomTreeEditor(Person)
}

/// RootView is ...
struct RootView: View {

    @EnvironmentObject var model: AppModel

    /// Body property for the RootView.
    var body: some View {
        NavigationStack(path: $model.path) {
            VStack {
                if model.database == nil {
                    LoaderView()
                        .navigationTitle(Text("Loading..."))
                } else if model.path.isEmpty {
                    PersonSelectionView()
                }
            }
            .environmentObject(model)
            // The closure builds Views when the navigation system finds a matching route on the navigation stack.
            // This code runs when code elsewhere 'model.path.append(Route.personEditor(person))' is called.
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .person(let person):
                    PersonView(person: person)
                case .pedigree(let person):
                    PedigreeView(person: person, generations: 4, buttonWidth: 400)
                case .family(let family):
                    FamilyView(family: family)
                case .descendants(let p):
                    DescendantsView(root: p)
                case .familyTree(let person):
                    FamilyTreeView(person: person)
                case .personEditor(let person):
                    // Create PersonEditorView with closure that runs when save button is pushed.
                    PersonEditorView(person: person) { newPerson in
                        model.database?.updatePerson(newPerson)
                        model.path.removeLast()  // Pop the editor view.
                    }
                case .personEditorNew(let person):
                    PersonEditorViewNew(person: person) { newPerson in
                        model.database?.updatePerson(newPerson)
                        model.path.removeLast()
                    }
                case .gedcomTreeEditor(let person):
                    if let db = model.database {
                        let manager = GedcomTreeManager(database: db)
                        GedcomTreeEditor(
                            viewModel: manager.treeModel,
                            manager: manager,
                            root: person.root
                        )
                    } else {
                        Text("No database loaded")
                    }
                case .descendancy(let person):
                    if let idx = model.database?.recordIndex {
                        DescendancyListView(root: person, index: idx)
                            .environmentObject(model)
                            .navigationTitle("Descendancy")
                    } else {
                        Text("No record index or person available.")
                    }
                }
            }
        }
    }
}
