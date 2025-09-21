//
//  PersonRow.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 4 July 2025.
//  Last changed on 19 September 2025.
//

import SwiftUI
import DeadEndsLib

// PersonRow is a wideish button.
struct PersonRow: View {
    @EnvironmentObject var model: AppModel
    let person: Person
    var label: String? = nil
    var showSummary: Bool = true
    var isInteractive: Bool = true
    var tint: Color? = nil

    var body: some View {
        let content = VStack(alignment: .leading) {
            HStack {
                if let label = label {
                    Text("\(label):")
                        .fontWeight(.medium)
                }
                Text(person.displayName())
                    .fontWeight(.semibold)
            }
            if showSummary {
                HStack(spacing: 8) {
                    if let birth = person.eventSummary(tag: "BIRT") {
                        Text("b. \(birth)").foregroundColor(.secondary)
                    }
                    if let death = person.eventSummary(tag: "DEAT") {
                        Text("d. \(death)").foregroundColor(.secondary)
                    }
                }
                .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(backgroundColor(for: person))
        .cornerRadius(6)

        if isInteractive {
            Button {
                model.path.append(Route.person(person))
            } label: {
                content
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            //.buttonStyle(.plain)
            .buttonStyle(PlainButtonStyle())
        } else {
            content
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
