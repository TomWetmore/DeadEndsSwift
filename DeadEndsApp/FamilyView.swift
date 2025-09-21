//
//  FamilyView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 11 July 2025.
//  Last changed on 19 September 2025.
//

import SwiftUI
import DeadEndsLib

// Provides the top level View of a Family.
struct FamilyView: View {

    @EnvironmentObject var model: AppModel
    let family: Family  // Family in View.

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Display Husband.
            if let husband = resolveRole("HUSB") {
                PersonRow(person: husband, label: "Husband")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            // Display Wife.
            if let wife = resolveRole("WIFE") {
                PersonRow(person: wife, label: "Wife")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            // Display Children.
            ScrollView {
                if let index = model.database?.recordIndex {
                    ForEach(family.children(in: index), id: \.self) { child in
                        PersonRow(person: child, label: "Child")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding()
        }
        .padding()
        .navigationTitle("Family")
    }

    private func resolveRole(_ tag: String) -> Person? {
        guard let key = family.kid(withTag: tag)?.val else { return nil }
        return model.database?.recordIndex.person(for: key)
    }
}
