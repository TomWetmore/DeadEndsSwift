//
//  PersonSearchGridPanel.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 2/25/26.
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

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {

            GridRow {
                Text("Name")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                TextField("Givens/Surname", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
            }

            GridRow {
                Text("Birth date")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                yearRangeRow(from: $birthFrom, to: $birthTo)
            }

            GridRow {
                Text("Death date")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                yearRangeRow(from: $deathFrom, to: $deathTo)
            }

            GridRow {
                Text("Birth place")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                TextField("e.g. Newburyport, MA", text: $birthPlace)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
            }

            GridRow {
                Text("Death place")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                TextField("e.g. Boston, MA", text: $deathPlace)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
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

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    PersonSearchGridPanel()
        .frame(width: 520)
}
