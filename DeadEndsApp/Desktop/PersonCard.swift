//
//  PersonCard.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 25 October 2025.
//  Last changed on 27 January 2026.
//

import SwiftUI
import DeadEndsLib

/// Views that are manipulated on a Desktop. Each View represents a Person in the DeadEnds 
struct PersonCard: View {

    let model: DesktopModel
    @Environment(\.recordIndex) private var index: RecordIndex
    var person: Person  // Person on card.

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(person.name ?? "Unknown Person")
                .font(.headline)
            if let birth = person.eventSummary(tag: "BIRT") {
                Text("b. \(birth)").foregroundColor(.secondary)
            }
            if let death = person.eventSummary(tag: "DEAT") {
                Text("d. \(death)").foregroundColor(.secondary)
            }
       }
    }
}

/// Context menu on person cards.
struct PersonContextMenu: View {
    
    let person: Person
    let index: RecordIndex

    // Use a non-observed reference so menu doesn’t re-render on every model change.
    weak var model: DesktopModel?

    var body: some View {
        // Compute once per render pass
        let spouseList = person.spouses(in: index)

        Group {
            Button("Add Spouse") { print("TODO -- Add Spouse") }
            Button("Show on Tree") { print("TODO -- Do something reasonable") }

            if spouseList.isEmpty {
                Button("No known spouse") {}.disabled(true)
            } else {
                // Check person's spouses against persons now in card array.
                ForEach(spouseList, id: \.root.key) { spouse in
                    if !(model?.contains(person: spouse) ?? false) {
                        Button("Add \(spouse.name ?? "no name")") {
                            model?.addCard(  // Add spouse to desktop.
                                kind: .person(spouse),
                                position: CGPoint(x: 200, y: 200),
                                size: CardSizes.startSize
                            )
                        }
                    }
                }
            }

            Divider()

            Button("Remove \(person.name ?? "no name")") {
                model?.removeCard(kind: .person(person))  // Remove person from desktop.
            }
        }
    }
}

@ViewBuilder
func familyContextMenu(_ family: Family) -> some View {
    Button("Add Children") { print("Hello, friend") }
}
