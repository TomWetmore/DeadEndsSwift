//
//  GetPersonSheet.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 21 May 2026.
//  Last changed on 21 May 2026.
//

import SwiftUI
import DeadEndsLib

struct GetPersonSheet: View {
    let request: PersonRequest
    let database: Database
    let onChoose: (Person) -> Void
    let onCancel: () -> Void

    @State private var pattern = ""
    @State private var results: [Person] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(request.prompt)
                .font(.headline)

            HStack {
                TextField("Name pattern", text: $pattern)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(search)

                Button("Search") {
                    search()
                }
            }

            List(results, id: \.key) { person in
                Button {
                    onChoose(person)
                } label: {
                    PersonChoiceRow(person: person)
                }
                .buttonStyle(.plain)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    onCancel()
                }
            }
        }
        .padding()
        .frame(minWidth: 520, minHeight: 420)
    }

    private func search() {
        results = database.persons(withName: pattern)
    }
}

struct PersonChoiceRow: View {
    let person: Person

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(person.displayName())
                .font(.title3)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subtitle: String {
        let birth = person.birthEvent?.summary
        let death = person.deathEvent?.summary

        switch (birth, death) {
        case let (b?, d?): return "born \(b) — died \(d)   \(person.key)"
        case let (b?, nil): return "born \(b)   \(person.key)"
        case let (nil, d?): return "died \(d)   \(person.key)"
        default: return person.key
        }
    }
}
