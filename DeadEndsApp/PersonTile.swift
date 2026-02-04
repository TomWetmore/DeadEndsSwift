//
//  PersonTile.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 4 July 2025.
//  Last changed on 1 February 2026.
//

import SwiftUI
import DeadEndsLib

/// Flexible view to show a person on a page views.
struct PersonTile: View {

    @EnvironmentObject var model: AppModel
    let person: Person
    var label: String? = nil
    var showSummary: Bool = true
    var tint: Color? = nil
    var onActivate: ((Person) -> Void)? = nil  // Button action.

    var body: some View {

        let content = VStack(alignment: .leading) {
            HStack {
                if let label = label {  // Optional label.
                    Text("\(label):")
                        .fontWeight(.medium)
                }
                Text(person.displayName())  // Name.
                    .fontWeight(.semibold)
            }
            if showSummary {  // Birth and death.
                VStack(alignment: .leading) {
                    if let birth = person.eventSummary(kind: .birth) {
                        Text("b. \(birth)").foregroundColor(.secondary)
                    }
                    if let death = person.eventSummary(kind: .death) {
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

        if let onActivate {
            Button {
                onActivate(person)
            } label: {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }
}
