//
//  PersonTile.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 4 July 2025.
//  Last changed on 10 January 2026.
//

import SwiftUI
import DeadEndsLib

/// Flexible view for showing a person.
struct PersonTile: View {

    @EnvironmentObject var model: AppModel
    let person: Person
    var label: String? = nil
    var showSummary: Bool = true
    var tint: Color? = nil
    var onActivate: ((Person) -> Void)? = nil

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
                VStack(alignment: .leading) {
                    if let birth = person.eventSummary(tag: "BIRT") {
                        Text("b. \(birth)").foregroundColor(.secondary)
                    }
                    if let death = person.eventSummary(tag: "DEAT") {
                        Text("d. \(death)").foregroundColor(.secondary)
                    }
                }
                .font(.title3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(backgroundColor(for: person))
        .cornerRadius(6)

        if let onActivate {  // Handle the view if it is can be a button.
            Button {
                onActivate(person)
            } label: {
                content
                //.frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }
}
