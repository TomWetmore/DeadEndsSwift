//
//  FamilySelectionView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 14 July 2025.
//  Last changed on 14 July 2025
//

import SwiftUI
import DeadEndsLib

// THIS FILE IS CURRENTLY NOT BEING USED (TRYING OUT USING A SHEET INSTEAD)


struct FamilySelectionView: View {
    @EnvironmentObject var model: AppModel
    let families: [GedcomNode]

    var body: some View {
        List(families, id: \.self) { family in
            Button {
                model.path.append(Route.family(family))
            } label: {
                Text(displayFamilySummary(family)) // Show spouses/children or marriage date
            }
        }
        .navigationTitle("Select Family")
    }
}
