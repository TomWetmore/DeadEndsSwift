//
//  RootView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 24 June 2025.
//  Last changed on 14 July 2025.
//

import SwiftUI
import DeadEndsLib

struct RootView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        NavigationStack(path: $model.path) {
            VStack {
                if model.database == nil {
                    LoaderView()
                } else if model.path.isEmpty {
                    //SelectPersonView()
                    PersonSelectionView()
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .person(let person):
                    PersonView(person: person)
                case .pedigree(let person):
                    PedigreeView(person: person, generations: 4, buttonWidth: 200)
                case .family(let family):
                    FamilyView(family: family)
                }
            }
        }
    }
}

enum Route: Hashable {
    case person(GedcomNode)
    case pedigree(GedcomNode)
    case family(GedcomNode)
}
