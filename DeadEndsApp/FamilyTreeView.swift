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

//    private func ospouseNames(_ person: Person) -> [String] {
//        guard let index = model.database?.recordIndex else { return [] }
//        // For each FAMS family, find the spouse (the other partner) and return displayName.
//        let families: [Family] = person.kids(withTag: "FAMS")
//            .compactMap { $0.val.flatMap { index.family(for: $0) } }
//
//        func spouseInFamily(_ family: Family) -> Person? {
//            // Return the partner who is not person.
//            let candidates = family.kids(withTag: "HUSB") + family.kids(withTag: "WIFE")
//            let spouseKeys: [String] = candidates.compactMap { $0.val }
//            let spousePersons = spouseKeys.compactMap { index.person(for: $0) }
//            return spousePersons.first { $0 != person }
//        }
//
//        return families.compactMap { spouseInFamily($0)?.displayName() }
//    }

    private func spouseNames(_ person: Person) -> [String] {
        print("spouseNames")
        guard let index = model.database?.recordIndex else { return [] }
        return person.spouses(in: index).map { $0.displayName() }
    }
}
