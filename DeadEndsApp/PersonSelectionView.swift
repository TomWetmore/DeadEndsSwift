//
//  PersonSelectionView.swift
//  DisplayPerson
//
//  Created by Thomas Wetmore on 28 June 2025.
//  Last changed 18 July 2025.
//

import SwiftUI
import DeadEndsLib

// PersonMatch is a struct using a Gedcom key for an id, and a Gedcom node.
struct PersonMatch: Identifiable {
    let id: String // Key of an INDI node.
    let node: GedcomNode // INDI node.

    var displayLine: String {
        let name = node.displayName()
        let birth = node.eventSummary(tag: "BIRT")
        let death = node.eventSummary(tag: "DEAT")
        switch (birth, death) {
        case let (b?, d?): return "\(name) (born \(b) — died \(d))"
        case let (b?, nil): return "\(name) (born \(b))"
        case let (nil, d?): return "\(name) (died \(d))"
        default: return name
        }
    }
}

// PersonSelectionView is a View that searches for a list of persons by name and allows user to
// select one.

struct PersonSelectionView: View {

    @EnvironmentObject var model: AppModel
    @State private var query: String = ""
    @State private var results: [PersonMatch] = []

    var body: some View {
        VStack(alignment: .leading) {
            Text("Enter a name to search for:")
                .font(.body)
            HStack {
                TextField("e.g. Thomas/Wetmore", text: $query)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        performSearch()
                    }
                Button("Search for persons with name") {
                    performSearch()
                }
            }
            .padding(.bottom)

            if results.isEmpty {
                Text("No results yet.").italic()
            } else {
                List(results) { match in
                    Button {
                        model.path.append(Route.person(match.node))
                    } label: {
                        Text(match.displayLine)
                            .padding(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
    }

    // performSearch sets the results array; it has access to model, results, and query.
    // Synopsis: if there is a database, look up the persons matching the query (a partial name);
    // convert each match (an INDI node) into a PersonMatch object; sort those objects alphabetically
    // by name; assign the result to results.
    private func performSearch() {
        guard let db = model.database else { return }
        results = db.persons(withName: query).map { PersonMatch(id: $0.key!, node: $0) }
            .sorted {
                ($0.node.gedcomName ?? GedcomName("")) < ($1.node.gedcomName ?? GedcomName(""))
            }
    }
}
