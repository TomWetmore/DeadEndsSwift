//
//  PersonPage.swift
//  DisplayPerson
//
//  Created by Thomas Wetmore on 20 June 2025.
//  Last changed on 21 June 2026.
//

import SwiftUI
import DeadEndsLib

/// Show person on a person page. Uses person tiles and a person action bar.
struct PersonPage: View {

    @Environment(AppModel.self) var model
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
                    guard let db = model.database else { return [] }
                    return db.searchPersons(crit)
                },
                onSelect: { key in
                    guard let person = model.database?.recordIndex.person(for: key) else { return }
                    model.path.append(Route.person(person))
                },
                resultDescription: { result in
                    guard let db = model.database else { return result.key }
                    return result.searchResultDescription(in: db.recordIndex)
                }
            )
        }
        .contextMenu {
            Button("Search…") { showingSearch = true }
            Divider()
            Button("Clear Search Criteria") { searchCriteria = SearchCriteria() }
        }
    }
}

/// Person page subviews that are implemented as computed properties.
private extension PersonPage {
    
    /// Subview that shows the person's name.
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
    
    /// Subview that shows the person's vitals.
    var vitals: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Born: \(person.birthEvent?.summary ?? "")")
            Text("Death: \(person.deathEvent?.summary ?? "")")
        }
        .padding(.horizontal)
    }
    
    /// Subview that shows the person's relatives.
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
    
    /// Subview that shows the persons's parents.
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
    
    /// Subview that shows the person's spouses and children.
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

    /// Subview that shows the status message and action bar.
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
