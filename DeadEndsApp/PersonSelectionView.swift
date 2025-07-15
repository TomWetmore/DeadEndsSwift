//
//  PersonSelectionView.swift
//  DisplayPerson
//
//  Created by Thomas Wetmore on 28 June 2025.
//  Last changed 29 June 2025.
//

import SwiftUI
import DeadEndsLib

// Simple model for displaying a matched person.
struct PersonMatch: Identifiable {
    let id: String // GEDCOM key
    let node: GedcomNode

    var olddisplayLine: String {
        let name = node.displayName()
        let birth = node.eventSummary(tag: "BIRT") ?? "?"
        let death = node.eventSummary(tag: "DEAT") ?? "?"
        return "\(name) (b. \(birth) — d. \(death))"
    }

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

// View for searching persons by name and selecting one.
struct PersonSelectionView: View {

    @EnvironmentObject var model: AppModel
    @State private var query: String = ""
    @State private var results: [PersonMatch] = []

    var body: some View {
        VStack(alignment: .leading) {
            Text("Enter a name to search for:")
                .font(.headline)
            HStack {
                TextField("e.g. Thomas/Wetmore", text: $query)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        performSearch()
                    }
                Button("Search") {
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

    // performSearch sets the results array; as a method it has access to model, results, and query.
    private func performSearch() {
        guard let db = model.database else { return } // Get the database.
        results =  db.persons(withName: query).map { PersonMatch(id: $0.key!, node: $0) }
            .sorted {
                ($0.node.gedcomName ?? GedcomName("")) < ($1.node.gedcomName ?? GedcomName(""))
            }
    }
}
