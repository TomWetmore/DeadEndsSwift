//
//  FamilyTreeView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 8 August 2025.
//  Last changed on 29 May 2026.
//

import SwiftUI
import DeadEndsLib

struct FamilyTreeView: View {

    @Environment(AppModel.self) var model
    let person: Person

    var body: some View {
        FamilyTreePersonView(
            name: person.displayName(),
            subtitle: lifespanLine(person),
            spouses: spouseNames(person)
        )
        .navigationTitle("Family Tree")
    }

    // MARK: - Helpers

    private func lifespanLine(_ person: Person) -> String? {
        //let b = p.birthDate?.simpleString ?? ""
        let b = "On some date"
        //let d = p.deathDate?.simpleString ?? ""
        let d = "At some place"
        if b.isEmpty && d.isEmpty { return nil }
        return "b. \(b)\(d.isEmpty ? "" : " – d. \(d)")"
    }

    private func spouseNames(_ person: Person) -> [String] {
        print("spouseNames")
        guard let index = model.database?.recordIndex else { return [] }
        return person.spouses(in: index).map { $0.displayName() }
    }
}
