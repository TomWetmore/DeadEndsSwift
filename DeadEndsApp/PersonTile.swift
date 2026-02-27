//
//  PersonTile.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 4 July 2025.
//  Last changed on 26 February 2026.
//

import SwiftUI
import DeadEndsLib

/// Flexible view to show a person on page views. Intended as a general purpose person
/// view for use in many contexts.
struct PersonTile: View {

    @EnvironmentObject var model: AppModel
    let person: Person
    var label: String? = nil
    var showSummary: Bool = true
    var onActivate: ((Person) -> Void)? = nil  // Button action.

    /// Render a person in a tile.
    var body: some View {

        // Computed property for view content.
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

        if let onActivate {  // Render content in a button if there is an activate closure.
            Button {
                onActivate(person)
            } label: {
                content
            }
            .buttonStyle(.plain)
        } else {
            content  // Otherwise render the content on its own.
        }
    }
}
