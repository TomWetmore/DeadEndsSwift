//
//  PersonSelectionSheet.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 14 January 2026.
//  Last changed on 27 February 2026.
//

import SwiftUI
import DeadEndsLib

/// Person select request.
struct PersonSelectRequest: Identifiable {
    let id = UUID()
    let title: String
    let persons: [Person]
}

/// Sheet for selecting a person from a list.
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

            List(persons, id: \.key) { person in  // Render list of persons as buttons.
                Button {
                    onSelect(person)
                    dismiss()
                } label: {
                    Text(person.displayName(upSurname: true))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(4)
                }
            }
            .frame(minHeight: 400)

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
