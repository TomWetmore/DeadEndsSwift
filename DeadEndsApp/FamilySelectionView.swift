//
//  FamilySelectionView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 14 July 2025.
//  Last changed on 29 May 2026.
//

import SwiftUI
import DeadEndsLib

// THIS FILE IS CURRENTLY NOT BEING USED (TRYING OUT USING A SHEET INSTEAD)


struct FamilySelectionView: View {
    
    @Environment(AppModel.self) var model
    let families: [Family]

    var body: some View {
        List(families, id: \.self) { family in
            Button {
                model.path.append(Route.family(family))
            } label: {
                Text("SOME DUMMY STUFF") // Show spouses/children or marriage date
            }
        }
        .navigationTitle("Select Family")
    }
}
