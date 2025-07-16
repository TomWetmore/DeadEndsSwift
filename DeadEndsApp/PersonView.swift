//
//  PersonView.swift
//  DisplayPerson
//
//  Created by Thomas Wetmore on 20 June 2025.
//  Last changed on 15 July 2025
//

import Foundation
import SwiftUI
import DeadEndsLib

struct PersonView: View {
    @State private var showFamilySelector = false
    @State private var candidateFamilies: [GedcomNode] = []
    @EnvironmentObject var model: AppModel
    let person: GedcomNode

    var body: some View {

        VStack(alignment: .leading, spacing: 10) {

            Text(person.displayName(uppercaseSurname: true))
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
                    //PersonButton(person: father, relation: "father")
                }

                // Mother
                if let ri = model.database?.recordIndex,
                   let mother = person.resolveParent(sex: "F", recordIndex: ri) {
                    //PersonButton(person: mother, relation: "mother")
                    PersonRow(person: mother, label: "Mother", tint: .pink)
                }

                Divider()

                if let ri = model.database?.recordIndex {
                    let families = person.children(withTag: "FAMS").compactMap { node in
                        node.value.flatMap { ri[$0] }
                    }

                    ForEach(families, id: \.self) { family in
                        if let spouse = family.resolveSpouse(for: person, recordIndex: ri) {
                            //PersonButton(person: spouse, relation: "spouse")
                            PersonRow(person: spouse, label: "Spouse", tint: backgroundColor(for: spouse))
                        }

                        let children = family.children(withTag: "CHIL").compactMap { node in
                            node.value.flatMap { ri[$0] }
                        }

                        ForEach(children, id: \.self) { child in // Works here but not in family selection??
                            //PersonButton(person: child, relation: "child")
                            PersonRow(person: child, label: "Child", tint: backgroundColor(for: child))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
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
        .navigationTitle("Person")
    }
}

public extension GedcomNode {

    // resolveParent returns the first parent of the specified sex to the self person.
    // It only looks in the first FAMC family.
    func resolveParent(sex: String, recordIndex: [String: GedcomNode]) -> GedcomNode? {
        guard let famc = self.child(withTag: "FAMC"),
              let familyKey = famc.value,
              let family = recordIndex[familyKey],
              let parentKey = family.child(withTag: sex == "M" ? "HUSB" : "WIFE")?.value,
              let parent = recordIndex[parentKey] else {
            return nil
        }
        return parent
    }
}

public extension GedcomNode {

    func getSpouse(for person: GedcomNode, recordIndex: [String: GedcomNode]) -> GedcomNode? {
        // Called on a FAM record
        let husbKey = self.child(withTag: "HUSB")?.value
        let wifeKey = self.child(withTag: "WIFE")?.value
        let selfKey = person.key

        if husbKey == selfKey, let wifeKey, let wife = recordIndex[wifeKey] {
            return wife
        }
        if wifeKey == selfKey, let husbKey, let husb = recordIndex[husbKey] {
            return husb
        }
        return nil
    }

    func resolveSpouse(for person: GedcomNode, recordIndex: [String: GedcomNode]) -> GedcomNode? {
        getSpouse(for: person, recordIndex: recordIndex)
    }
}

struct PersonButton: View {
    @EnvironmentObject var model: AppModel
    let person: GedcomNode
    var relation: String?

    var body: some View {
        Button {
            model.path.append(Route.person(person))
        } label: {
            HStack {
                if let relation = relation {
                    Text("\(relation):")
                        .fontWeight(.semibold)
                }
                Text(person.displayName())
            }
            .padding(4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor(for: person))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// backgroundColor ...
func backgroundColor(for person: GedcomNode) -> Color {
    guard let sex = person.node(withPath: ["SEX"])?.value else {
        return Color.gray.opacity(0.1)
    }
    switch sex {
    case "M": return Color.blue.opacity(0.08)
    case "F": return Color.pink.opacity(0.08)
    default:  return Color.gray.opacity(0.08)
    }
}
