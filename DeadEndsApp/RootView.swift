//
//  RootView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 24 June 2025.
//  Last changed on 21 August 2025.
//

import SwiftUI
import DeadEndsLib

// RootView is ...
struct RootView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        NavigationStack(path: $model.path) {
            VStack {
                if model.database == nil {
                    LoaderView()
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
                }
            }
        }
    }
}

// Route is in enumeration of the values that are pushed on a NavigationStack.
enum Route: Hashable {
    case person(GedcomNode)
    case pedigree(GedcomNode)
    case family(GedcomNode)
    case descendants(GedcomNode)
    case familyTree(GedcomNode)
}
