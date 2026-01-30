//
//  PedigreePage.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 14 January 2026.
//  Last changed on 28 January 2026.
//

import SwiftUI
import DeadEndsLib

struct PedigreePage: View {

    @EnvironmentObject var model: AppModel
    let person: Person  // Root of Pedigree.
    let generations: Int
    let buttonWidth: CGFloat  // Max button width.

    /// Render pedigree page.
    var body: some View {
        VStack {

            Text("Pedigree of \(person.displayName(upSurname: true))")
            PedigreeDetail(person: person, generations: generations, buttonWidth: buttonWidth)
            VStack(alignment: .leading, spacing: 4) {
                if let message = model.status {
                    Text(message)
                        .font(.callout)
                        .foregroundColor(.gray)
                }
                PedigreeActionBar(person: person)
            }
            .padding()

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .navigationTitle("Pedigree")
    }
}
