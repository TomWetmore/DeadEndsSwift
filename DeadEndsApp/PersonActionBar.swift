//
//  PersonActionBar.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 2 July 2025.
//  Last changed on 2 July 2025.
//

import SwiftUI
import DeadEndsLib

struct PersonActionBar: View {
    @EnvironmentObject var model: AppModel
    let person: GedcomNode

    var body: some View {
        HStack {
            Button("↑ Father") {
                navigateToParent(sex: "M")
            }
            Button("↓ Mother") {
                navigateToParent(sex: "F")
            }
            Button("← Older Sibling") {
                navigateToSibling(offset: -1)
            }
            Button("→ Younger Sibling") {
                navigateToSibling(offset: +1)
            }
            Button("Pedigree") {
                model.path.append(Route.pedigree(person))
            }
        }
        .buttonStyle(.bordered)
        //.buttonStyle(.borderedProminent)
        .font(.caption)
        .tint(.secondary)
        .padding(.top)
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
