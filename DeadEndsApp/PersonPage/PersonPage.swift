//
//  PersonPage.swift
//  DisplayPerson
//
//  Created by Thomas Wetmore on 20 June 2025.
//  Last changed on 26 February 2026.
//

import SwiftUI
import DeadEndsLib

/// Show person on a person page. Uses person tiles and a person action bar.
struct PersonPage: View {

    @EnvironmentObject private var model: AppModel
    let person: Person
    @State private var showingSearch = false
    @State private var searchCriteria = SearchCriteria()
    private var index: RecordIndex? { model.database?.recordIndex }

    /// Render person page.
    var body: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            header  // Name.
            vitals  // Birth and death.
            Divider()
            relativesScroll  // Parents, spouses, children.
            footer  // Status message and action bar.
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .navigationTitle("Person")

        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingSearch = true
                } label: {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .help("Search persons")
            }
        }

        .sheet(isPresented: $showingSearch) {
            PersonSearchPanel(
                criteria: $searchCriteria,
                onSearch: { crit in
                    print("search button pressed with \(crit)")
                    testPlaceIndexing()  // Debugging.
                    let results = model.database?.searchPersons(crit)
                    for result in results! {  // Debugging.
                        print(result.fullDescription(in: model.database!.recordIndex))
                    }
                    return []
                },
                onSelect: { key in
                    // Temporary: hook this to your navigation.
                    // Example possibilities:
                    // model.path.append(.person(key))
                    // model.currentPersonKey = key
                }
            )
            .environmentObject(model) // If SearchPanel needs it (currently doesn’t).
        }
        .contextMenu {
            Button("Search…") { showingSearch = true }
            Divider()
            Button("Clear Search Criteria") { searchCriteria = SearchCriteria() }
        }
    }
}

/// Subviews implemented as computed properties.
private extension PersonPage {
    
    /// Render name.
    var header: some View {
        Text(person.displayName(upSurname: true))
            .font(.title3)
            .fontWeight(.semibold)
            .padding(8)
            .background(person.sexTint)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
    
    /// Render vitals.
    var vitals: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Born: \(person.birthEvent?.summary ?? "")")
            Text("Death: \(person.deathEvent?.summary ?? "")")
        }
        .padding(.horizontal)
    }
    
    /// Render relatives in scroll view.
    var relativesScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                parentsSection
                Divider()
                familiesSection
            }
        }
        .padding(.top, 0)
        .padding(.horizontal, 8)
    }
    
    /// Render parents.
    @ViewBuilder
    var parentsSection: some View {
        if let index {
            if let father = person.father(in: index) {
                PersonTile(person: father, label: "Father") { person in
                    model.path.append(Route.person(person))
                }
            }
            if let mother = person.mother(in: index) {
                PersonTile(person: mother, label: "Mother") { person in
                    model.path.append(Route.person(person))
                }
            }
        }
    }
    
    /// Render spouses and children.
    @ViewBuilder
    var familiesSection: some View {
        if let index {
            ForEach(person.spouseFamilies(in: index), id: \.key) { family in
                if let spouse = family.spouse(of: person, in: index) {
                    PersonTile(person: spouse, label: "Spouse") { person in
                        model.path.append(Route.person(person))
                    }
                }
                ForEach(family.children(in: index), id: \.key) { child in
                    PersonTile(person: child, label: "Child") { person in
                        model.path.append(Route.person(person))
                    }
                }
            }
        }
    }

    /// Render status message and action bar.
    @ViewBuilder
    var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let message = model.status {
                Text(message)
                    .font(.callout)
                    .foregroundColor(.gray)
            }
            PersonActionBar(person: person)
        }
        .padding()
    }
}

extension Person {

    /// Background tint based on sex.
    var sexTint: Color {
        switch sex {
        case .male:   return Color.blue.opacity(0.05)
        case .female: return Color.pink.opacity(0.05)
        default:      return Color.gray.opacity(0.05)
        }
    }
}
