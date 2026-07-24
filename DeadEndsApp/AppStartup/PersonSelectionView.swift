//
//  PersonSelectionView.swift
//  DisplayPerson
//
//  Created by Thomas Wetmore on 28 June 2025.
//  Last changed on 24 July 2026.

/// This view is used on the RootView to get a list of persons so the
/// user can select one. The chosen person is opened on a PersonPage.

import SwiftUI
import DeadEndsLib

/// Struct that holds a matched person.
struct PersonMatch: Identifiable {

    let id: RecordKey
    let person: Person
}

/// View that shows a list of Persons with names that match
/// a pattern, and then allows the user to select one.
struct PersonSelectionView: View {

    @Environment(AppModel.self) var model
    @State private var namePattern: String = "" // Name pattern from user.
    @State private var results: [PersonMatch] = [] // Persons that match.

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
                        Text(match.person.displayLine)
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

    /// Get the PersonMatch objects that match a name pattern;
    /// they will be sorted by name and event dates.
    private func doNameSearch() {
        
        guard let database = model.database else { return }
        results = database.persons(withName: namePattern)
            .map { PersonMatch(id: $0.key, person: $0) }
    }
}
