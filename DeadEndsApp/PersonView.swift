//
//  PersonView.swift
//  DisplayPerson
//
//  Created by Thomas Wetmore on 20 June 2025.
//  Last changed on 21 September 2025.
//

import SwiftUI
import DeadEndsLib

/// View that show Person in a full resizable window.
struct PersonView: View {

    @EnvironmentObject var model: AppModel
    let person: Person
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            
            Text(person.displayName(upSurname: true))
                .font(.title3)
                .fontWeight(.semibold)
                .padding(8)
                .background(backgroundColor(for: person))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            Text("Born: \(person.eventSummary(tag: "BIRT") ?? "")").padding(.horizontal)
            Text("Death: \(person.eventSummary(tag: "DEAT") ?? "")").padding(.horizontal)
            
            Divider()
                .frame(height: 1)
                .padding(.horizontal)
                .padding(.bottom, 0)
            //.background(Color.gray.opacity(0.5))
            
            ScrollView {
                // Father
                if let ri = model.database?.recordIndex,
                   let father = person.resolveParent(sex: "M", recordIndex: ri) {
                    PersonRow(person: father, label: "Father", tint: .blue)
                }
                // Mother
                if let ri = model.database?.recordIndex,
                   let mother = person.resolveParent(sex: "F", recordIndex: ri) {
                    PersonRow(person: mother, label: "Mother", tint: .pink)
                }
                
                Divider()
                
                if let ri = model.database?.recordIndex {
                    let families = person.kids(withTag: "FAMS").compactMap { node in
                        node.val.flatMap { ri.family(for: $0) }
                    }
                    
                    ForEach(families, id: \.self) { family in
                        if let spouse = family.resolveSpouse(for: person, index: ri) {
                            PersonRow(person: spouse, label: "Spouse", tint: backgroundColor(for: spouse))
                        }
                        let children = family.kids(withTag: "CHIL").compactMap { node in
                            node.val.flatMap { ri.person(for: $0) }
                        }
                        ForEach(children, id: \.self) { child in
                            PersonRow(person: child, label: "Child", tint: backgroundColor(for: child))
                        }
                    }
                }
            }
            .padding([.top], 0)
            .padding([.leading, .trailing], 8)
            
            // Status area to give user important messages.
            VStack(alignment: .leading, spacing: 4) {
                if let message = model.status {
                    Text(message)
                        .font(.callout)
                        .foregroundColor(.gray)
                }
                PersonActionBar(person: person)
            }
            .padding()
            //.background(Color(.gray)) // optional but gives a footer effect
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .navigationTitle("Person")
    }
}

public extension Person {
    
    /// Returns the first parent of the specified sex of self.
    /// It only looks in the first FAMC family.
    func resolveParent(sex: String, recordIndex: RecordIndex) -> Person? {
        guard let familyKey = self.kidVal(forTag: "FAMC"),
              let family = recordIndex.family(for: familyKey),
              let parentKey = family.kid(withTag: sex == "M" ? "HUSB" : "WIFE")?.val,
              let parent = recordIndex.person(for: parentKey) else {
            return nil
        }
        return parent
    }
}

public extension Family {
    
    func resolveSpouse(for person: Person, index: RecordIndex) -> Person? {
        // Called on a FAM record
        let husbKey = self.kid(withTag: "HUSB")?.val
        let wifeKey = self.kid(withTag: "WIFE")?.val
        let selfKey = person.key
        if husbKey == selfKey, let wifeKey, let wife = index.person(for: wifeKey) { return wife }
        if wifeKey == selfKey, let husbKey, let husb = index.person(for: husbKey) { return husb }
        return nil
    }
}

/// backgroundColor ...
func backgroundColor(for person: Person) -> Color {
    let sexType = person.sex
    switch sexType {
    case .male: return Color.blue.opacity(0.05)
    case .female: return Color.pink.opacity(0.05)
    default:  return Color.gray.opacity(0.05)
    }
}
