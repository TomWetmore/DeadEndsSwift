//
//  PersonSelectionView.swift
//  DisplayPerson
//
//  Created by Thomas Wetmore on 28 June 2025.
//  Last changed on 7 March 2026.

/// PersonSelectionView is used on the RootView to get a list of persons
/// from a name pattern that the user selects an member of. The person chosen
/// is then opened in the PersonPage view.
///
/// Currently only used on the RootView.

import SwiftUI
import DeadEndsLib

/// PersonMatch is a struct with a Gedcom key for id, and a Person record.
struct PersonMatch: Identifiable {
    let id: String // Person key.
    let person: Person

    var displayLine: String {
        let name = person.displayName()
        let birth = person.birthEvent?.summary
        let death = person.deathEvent?.summary
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
    @State private var namePattern: String = ""
    @State private var results: [PersonMatch] = []

    var body: some View {
        VStack(alignment: .leading) {
            Text("Enter a name to search for:")
                .font(.body)
            HStack {
                TextField("e.g. William/James", text: $namePattern)
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
                        model.path.append(Route.person(match.person))  // Goto person page.
                    } label: {
                        Text(match.displayLine)
                            .font(.title3)
                            .padding(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
    }

    /// Build array of PersonMatch objects that match query; sort them by name, and
    /// user event dates to improve the order.
    private func doNameSearch() {
        guard let database = model.database else { return }
        let index = database.recordIndex

        results = database.persons(withName: namePattern)
            .map { PersonMatch(id: $0.key, person: $0) }
            .sorted { lhs, rhs in
                switch lhs.person.compare(to: rhs.person, in: index) {
                case .orderedAscending:
                    return true
                case .orderedDescending:
                    return false
                case .orderedSame:
                    return lhs.id < rhs.id
                }
            }
    }
}
