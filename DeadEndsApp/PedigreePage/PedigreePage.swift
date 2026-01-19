//
//  PedigreePage.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 14 January 2026.
//  Last changed on 14 January 2026.
//

/// This is the overall page for showing Pedigrees. It should show a header, the detail (actual pedigree), and
/// the status and pedigree action buttons.

import SwiftUI
import DeadEndsLib

struct PedigreePage: View {

    @EnvironmentObject var model: AppModel
    let person: Person  // Root of Pedigree.
    let generations: Int  // Number of generations.
    let buttonWidth: CGFloat  // Max button width.

    var body: some View {
        VStack {
            
            // Page header.
            Text("Pedigree of \(person.displayName(upSurname: true))")

            // Pedigree.
            PedigreeDetail(person: person, generations: generations, buttonWidth: buttonWidth)

            // Button bar and status.
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
