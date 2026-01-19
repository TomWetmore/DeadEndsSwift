//
//  PersonSelectionSheet.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 14 January 2026.
//  Last changed on 14 January 2026.
//

import SwiftUI
import DeadEndsLib

/// Structure holding list of persons.
struct PersonList: Identifiable {
    let id = UUID()
    let title: String
    let persons: [Person]
}

/// Sheet view for selecting from a list of persons.
struct PersonSelectionSheet: View {

    let title: String
    let persons: [Person]
    let onSelect: (Person) -> Void

    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

            Divider()

            List(persons, id: \.key) { person in
                Button {
                    onSelect(person)
                    dismiss()
                } label: {
                    Text(person.displayName(upSurname: true))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(4)
                }
            }
            .frame(minHeight: 200)

            Divider()

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                    .padding()
            }
        }
        .frame(width: 400)
        .frame(minHeight: 300)
        .padding()
    }
}
