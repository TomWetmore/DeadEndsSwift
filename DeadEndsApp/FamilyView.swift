//
//  FamilyView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 11 July 2025.
//  Last changed on 14 July 2025.
//

import SwiftUI
import DeadEndsLib

// FamilyView is the 'top-level' View of a Family.
struct FamilyView: View {
    @EnvironmentObject var model: AppModel
    let family: GedcomNode

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {
            if let husband = resolveRole("HUSB") {
                PersonRow(person: husband, label: "Husband")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let wife = resolveRole("WIFE") {
                PersonRow(person: wife, label: "Wife")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            //Divider()
            ScrollView {

                ForEach(children, id: \.self) { child in
                    PersonRow(person: child, label: "Child")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding()
        }
        .padding()
        .navigationTitle("Family")
    }

    private func resolveRole(_ tag: String) -> GedcomNode? {
        guard let key = family.child(withTag: tag)?.value else { return nil }
        return model.database?.recordIndex[key]
    }

    private var children: [GedcomNode] {
        guard let ri = model.database?.recordIndex else { return [] }
        return family.children(withTag: "CHIL").compactMap { node in
            node.value.flatMap { ri[$0] }
        }
    }
}
