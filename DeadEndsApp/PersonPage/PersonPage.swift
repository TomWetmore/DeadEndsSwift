//
//  PersonPage.swift
//  DisplayPerson
//
//  Created by Thomas Wetmore on 20 June 2025.
//  Last changed on 1 February 2026.
//

import SwiftUI
import DeadEndsLib

/// Show a person on a person page. Uses a person action bar, person rows and message area.
struct PersonPage: View {

    @EnvironmentObject private var model: AppModel
    let person: Person

    private var index: RecordIndex? { model.database?.recordIndex }

    /// Render person page.
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            vitals
            Divider()
            relativesScroll
            footer
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .navigationTitle("Person")
    }
}

private extension PersonPage {
    
    /// Render person name.
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
    
    /// Render person vitals.
    var vitals: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Born: \(person.eventSummary(kind: .birth) ?? "")")
            Text("Death: \(person.eventSummary(kind: .death) ?? "")")
        }
        .padding(.horizontal)
    }
    
    /// Render person's parents, spouses, and children.
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
    
    /// Render person's parents.
    @ViewBuilder
    var parentsSection: some View {
        if let index {
            if let father = person.father(in: index) {
                PersonTile(person: father, label: "Father", tint: .blue) { person in
                    model.path.append(Route.person(person))
                }
            }
            if let mother = person.mother(in: index) {
                PersonTile(person: mother, label: "Mother", tint: .pink) { person in
                    model.path.append(Route.person(person))
                }
            }
        }
    }
    
    /// Render person's spouses and children.
    @ViewBuilder
    var familiesSection: some View {
        if let index {
            ForEach(person.spouseFamilies(in: index), id: \.key) { family in
                if let spouse = family.spouse(of: person, in: index) {
                    PersonTile(person: spouse, label: "Spouse", tint: spouse.sexTint) { person in
                        model.path.append(Route.person(person))
                    }
                }
                ForEach(family.children(in: index), id: \.key) { child in
                    PersonTile(person: child, label: "Child", tint: child.sexTint) { person in
                        model.path.append(Route.person(person))
                    }
                }
            }
        }
    }

    /// Render footer
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
