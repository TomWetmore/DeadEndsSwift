//
//  FamilyTreeView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 8/8/25.
//  Coalesced by ChatGPT on 8/8/25.
//
//

import SwiftUI
import DeadEndsLib

struct FamilyTreeView: View {
    @EnvironmentObject var model: AppModel
    let person: GedcomNode

    var body: some View {
        FamilyTreePersonView(
            name: person.displayName(),
            subtitle: lifespanLine(person),
            spouses: spouseNames(person)
        )
        .navigationTitle("Family Tree")
    }

    // MARK: - Helpers

    private func lifespanLine(_ p: GedcomNode) -> String? {
        // Adjust to your actual helpers; this is a safe placeholder.
        //let b = p.birthDate?.simpleString ?? ""
        let b = "On some date"
        //let d = p.deathDate?.simpleString ?? ""
        let d = "At some place"
        if b.isEmpty && d.isEmpty { return nil }
        return "b. \(b)\(d.isEmpty ? "" : " – d. \(d)")"
    }

    private func spouseNames(_ p: GedcomNode) -> [String] {
        guard let ri = model.database?.recordIndex else { return [] }
        // For each FAMS family, find the spouse (the other partner) and return displayName.
        let families: [GedcomNode] = p.children(withTag: "FAMS")
            .compactMap { $0.value.flatMap { ri[$0] } }

        func spouseInFamily(_ family: GedcomNode) -> GedcomNode? {
            // Typical GEDCOM: HUSB / WIFE (or generalized spouse roles).
            // Return the partner who is NOT `person`.
            let candidates = family.children(withTag: "HUSB") + family.children(withTag: "WIFE")
            let spouseKeys: [String] = candidates.compactMap { $0.value }
            let spousePersons = spouseKeys.compactMap { ri[$0] }
            return spousePersons.first { $0 != p }
        }

        return families.compactMap { spouseInFamily($0)?.displayName() }
    }
}
