//
//  PersonSelectionView.swift
//  DisplayPerson
//
//  Created by Thomas Wetmore on 28 June 2025.
//  Last changed 1 February 2026.
//

import SwiftUI
import DeadEndsLib

/// PersonMatch is a struct with a Gedcom key for id, and a Person record.
struct PersonMatch: Identifiable {
    let id: String // Person key.
    let person: Person

    var displayLine: String {
        let name = person.displayName() // Default formatting.
        let birth = person.eventSummary(kind: .birth)
        let death = person.eventSummary(kind: .death)
        switch (birth, death) {
        case let (b?, d?): return "\(name) (born \(b) — died \(d))"
        case let (b?, nil): return "\(name) (born \(b))"
        case let (nil, d?): return "\(name) (died \(d))"
        default: return name
        }
    }
}

/// A View that shows a list of Persons from a Database who have names that match
/// a pattern and allows the user to select one.
struct PersonSelectionView: View {

    @EnvironmentObject var model: AppModel
    @State private var query: String = ""  // Name pattern user supplies.
    @State private var results: [PersonMatch] = [] // PersonMatches that match the query pattern.

    var body: some View {
        VStack(alignment: .leading) {
            Text("Enter a name to search for:")
                .font(.body)
            HStack {
                TextField("e.g. William/James", text: $query)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        doNameSearch()
                    }
                Button("Search for persons with name") {
                    doNameSearch()
                }
            }
            .padding(.bottom)

            if results.isEmpty {
                Text("No results yet.").italic()
            } else {
                List(results) { match in
                    Button {
                        model.path.append(Route.person(match.person))
                    } label: {
                        Text(match.displayLine)
                            .font(.title3) // EXPERIMENT
                            .padding(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
    }

    /// Builds the array of PersonMatch objects that have names that match the query; sorts them by name.
    private func doNameSearch() {
        guard let database = model.database else { return }
        results = database.persons(withName: query)
            .map { PersonMatch(id: $0.key, person: $0) }
            .sorted { lhs, rhs in
                switch (lhs.person.gedcomName, rhs.person.gedcomName) {
                case let (l?, r?): return l < r                 // both present → use Comparable
                case (nil, nil):   return lhs.id < rhs.id       // stable tiebreaker
                case (nil, _):     return false                 // nils after non-nils
                case (_, nil):     return true
                }
            }
    }
}
