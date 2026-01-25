//
//  FamilyView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 11 July 2025.
//  Last changed on 25 January 2026.
//

import SwiftUI
import DeadEndsLib

// Provides the top level View of a Family.
struct FamilyPage: View {

    @EnvironmentObject var model: AppModel
    let family: Family  // Family in View.

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Display Husband.
            if let husband = resolveRole("HUSB") {
                PersonTile(person: husband, label: "Husband")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            // Display Wife.
            if let wife = resolveRole("WIFE") {
                PersonTile(person: wife, label: "Wife")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            // Display Children.
            ScrollView {
                if let index = model.database?.recordIndex {
                    ForEach(family.children(in: index), id: \.self) { child in
                        PersonTile(person: child, label: "Child")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding()

            // Messages and action buttons.
            VStack(alignment: .leading, spacing: 4) {
                if let message = model.status {
                    Text(message)
                        .font(.callout)
                        .foregroundColor(.gray)
                }
                FamilyActionBar(family: family)
            }
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
