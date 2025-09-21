//
//  RootView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 24 June 2025.
//  Last changed on 19 September 2025.
//

import SwiftUI
import DeadEndsLib

/// The enumeration of values that are pushed onto the DeadEndsApp NavigationStack.
enum Route: Hashable {
    case person(Person)
    case pedigree(Person)
    case family(Family)
    case descendants(Person)
    case familyTree(Person)
    case descendancy(Person)
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

