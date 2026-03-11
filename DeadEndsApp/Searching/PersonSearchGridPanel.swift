//
//  PersonSearchGridPanel.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 25 February 2026.
//  Last changed on 8 March 2026.
//

import SwiftUI

import SwiftUI

struct PersonSearchGridPanel: View {
    @State private var name = ""
    @State private var birthFrom = ""
    @State private var birthTo = ""
    @State private var deathFrom = ""
    @State private var deathTo = ""
    @State private var birthPlace = ""
    @State private var deathPlace = ""

    private let labelWidth: CGFloat = 100

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {

            GridRow {
                Text("Person Name")
                    .foregroundStyle(.secondary)
                    .frame(width: labelWidth, alignment: .trailing)

                TextField("Givens/Surname", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 320)
            }
            GridRow {
                Text("Birth date")
                    .foregroundStyle(.secondary)
                    .frame(width: labelWidth, alignment: .trailing)

                yearRangeRow(from: $birthFrom, to: $birthTo)
            }
            GridRow {
                Text("Death date")
                    .foregroundStyle(.secondary)
                    .frame(width: labelWidth, alignment: .trailing)

                yearRangeRow(from: $deathFrom, to: $deathTo)
            }

            GridRow {
                Text("Birth place")
                    .foregroundStyle(.secondary)
                    .frame(width: labelWidth, alignment: .trailing)

                TextField("name parts with commas", text: $birthPlace)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 320)
            }
            GridRow {
                Text("Death place")
                    .foregroundStyle(.secondary)
                    .frame(width: labelWidth, alignment: .trailing)

                TextField("e.g. Boston, Essex, New Brunswick, Kings County", text: $deathPlace)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 320)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func yearRangeRow(from: Binding<String>, to: Binding<String>) -> some View {
        HStack(spacing: 8) {
            Text("From").foregroundStyle(.secondary)

            TextField("YYYY", text: from)
                .textFieldStyle(.roundedBorder)
                .frame(width: 70)
                .multilineTextAlignment(.center)

            Text("To").foregroundStyle(.secondary)

            TextField("YYYY", text: to)
                .textFieldStyle(.roundedBorder)
                .frame(width: 70)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    PersonSearchGridPanel()
        .frame(width: 600)
}
