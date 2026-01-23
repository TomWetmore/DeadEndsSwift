//
//  PersonPage.swift
//  DisplayPerson
//
//  Created by Thomas Wetmore on 20 June 2025.
//  Last changed on 21 January 2026.
//

import SwiftUI
import DeadEndsLib

/// Show a person on a person page. Uses a person action bar, person rows and message area.
struct PersonPage: View {

    @EnvironmentObject var model: AppModel
    let person: Person
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            
            Text(person.displayName(upSurname: true))  // Name line.
                .font(.title3)
                .fontWeight(.semibold)
                .padding(8)
                .background(backgroundColor(for: person))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            Text("Born: \(person.eventSummary(tag: "BIRT") ?? "")").padding(.horizontal)  // Birth line.
            Text("Death: \(person.eventSummary(tag: "DEAT") ?? "")").padding(.horizontal)  // Death line.

            Divider()
                .frame(height: 1)
                .padding(.horizontal)
                .padding(.bottom, 0)
            
            ScrollView {
                if let ri = model.database?.recordIndex,
                   let father = person.resolveParent(sex: "M", index: ri) {  // Father tile.
                    PersonTile(person: father, label: "Father", tint: .blue) { p in
                        model.path.append(Route.person(p))
                    }
                }
                if let ri = model.database?.recordIndex,
                   let mother = person.resolveParent(sex: "F", index: ri) {  // Mother tile.
                    PersonTile(person: mother, label: "Mother", tint: .pink) { p in
                        model.path.append(Route.person(p))
                    }
                }
                
                Divider()
                
                if let ri = model.database?.recordIndex {
                    let families = person.kids(withTag: "FAMS").compactMap { node in
                        node.val.flatMap { ri.family(for: $0) }
                    }
                    
                    ForEach(families, id: \.self) { family in
                        if let spouse = family.resolveSpouse(for: person, index: ri) {
                            PersonTile(person: spouse, label: "Spouse", tint: backgroundColor(for: spouse)) { p in
                                model.path.append(Route.person(p))
                            }
                        }
                        let children = family.kids(withTag: "CHIL").compactMap { node in
                            node.val.flatMap { ri.person(for: $0) }
                        }
                        ForEach(children, id: \.self) { child in
                            PersonTile(person: child, label: "Child", tint: backgroundColor(for: child)) { p in
                                model.path.append(Route.person(p))
                            }
                        }
                    }
                }
            }
            .padding([.top], 0)
            .padding([.leading, .trailing], 8)
            
            // Messages and action buttons.
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .navigationTitle("Person")
    }
}

public extension Person {
    
    /// Return first parent with specified sex of self. It uses the first FAMC family.
    func resolveParent(sex: String, index: RecordIndex) -> Person? {
        guard let familyKey = self.kidVal(forTag: "FAMC"),
              let family = index.family(for: familyKey),
              let parentKey = family.kid(withTag: sex == "M" ? "HUSB" : "WIFE")?.val,
              let parent = index.person(for: parentKey) else {
            return nil
        }
        return parent
    }
}

public extension Family {

    /// Find first spouse of Person in self Family.
    
    func resolveSpouse(for person: Person, index: RecordIndex) -> Person? {

        let husbKey = self.kid(withTag: "HUSB")?.val
        let wifeKey = self.kid(withTag: "WIFE")?.val
        let selfKey = person.key
        if husbKey == selfKey, let wifeKey, let wife = index.person(for: wifeKey) { return wife }
        if wifeKey == selfKey, let husbKey, let husb = index.person(for: husbKey) { return husb }
        return nil
    }
}

/// Return backgroundColor of person based on sex.
/// Note: Should this be an extention on Person?

func backgroundColor(for person: Person) -> Color {
    
    let sexType = person.sex // Note: Remove this variable?
    switch sexType {
    case .male: return Color.blue.opacity(0.05)
    case .female: return Color.pink.opacity(0.05)
    default:  return Color.gray.opacity(0.05)
    }
}
