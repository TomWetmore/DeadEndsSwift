//
//  FamilyActionBar.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 24 January 2026.
//  Last changed on 29 May 2026.
//

import SwiftUI
import DeadEndsLib

struct FamilyActionBar: View {
    
    @Environment(AppModel.self) var model
    let family: Family
    @State private var showEditSheet = false

    var body: some View {
        HStack {
            Button("Open Desktop") {
                model.path.append(Route.desktopFamily(family))   // add this route
            }

            Button("Tree Editor") {
                model.path.append(Route.gedcomFamilyEditor(family)) // if you support family
            }

//            Button("Edit") {
//                showEditSheet = true
//            }
//            .sheet(isPresented: $showEditSheet) {
//                FamilyEditSheet(family: family)
//                    .environmentObject(model)
//            }
        }
        .buttonStyle(.bordered)
        .font(.body)
        .tint(.secondary)
        .padding(.top)
    }
}
