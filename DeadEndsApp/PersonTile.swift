//
//  PersonTile.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 4 July 2025.
//  Last changed on 7 March 2026.

/// PersonTile is used on several page views to show persons in small
/// tiles. Labels are optional and birth and death summaries are optional.
/// If a buttonAction is given the tile will be place in a button.

import SwiftUI
import DeadEndsLib

/// General view that shows a person in a tile shape.
struct PersonTile: View {
    @EnvironmentObject var model: AppModel
    let person: Person
    var label: String? = nil
    var showSummary: Bool = true
    var buttonAction: ((Person) -> Void)? = nil

    /// Render a person in a tile.
    var body: some View {
        let content = VStack(alignment: .leading) {
            HStack {
                if let label = label {  // Label.
                    Text("\(label):")
                        .fontWeight(.medium)
                }
                Text(person.displayName())  // Name.
                    .fontWeight(.semibold)
            }
            if showSummary {  // Birth and death.
                VStack(alignment: .leading) {
                    if let birth = person.birthEvent?.summary {
                        Text("b. \(birth)").foregroundColor(.secondary)
                    }
                    if let death = person.deathEvent?.summary {
                        Text("d. \(death)").foregroundColor(.secondary)
                    }
                }
                .font(.title3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(person.sexTint)
        .cornerRadius(6)

        if let buttonAction {  // Render tile in button if there is a closure.
            Button {
                buttonAction(person)
            } label: {
                content
            }
            .buttonStyle(.plain)
        } else {
            content  // Else render tile on its own.
        }
    }
}
