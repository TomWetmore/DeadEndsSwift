//
//  FamilySelectionSheet.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 14 July 2025.
//  Last changed on 14 January 2026.
//

import SwiftUI
import DeadEndsLib

// Allow user to select a family from an array of families.
struct FamilySelectionSheet: View {

    let families: [Family]  // Array of families to select from.
    let onSelect: (Family) -> Void  // Closure to call on selected FAM node.

    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Text("Select Family")
                .font(.headline)
                .frame(alignment: .leading)
                .padding()

            Divider()

            if let recordIndex = model.database?.recordIndex {
                List(families, id: \.key) { family in
                    Button {
                        onSelect(family)
                    } label: {
                        Text(familySummary(family, index: recordIndex))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(4)
                    }
                }
                .frame(minHeight: 200) // Ensures the List has enough space
            } else {
                Text("No database loaded")
            }

            Divider()

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .padding()
            }
        }
        .frame(width: 400)
        .frame(minHeight: 300) // <-- Controls total sheet size
        .padding()
    }

    /// Return string used to represent a family on the sheet.
    private func familySummary(_ fam: Family, index: RecordIndex) -> String {
        let husbName = fam.husband(in: index)?.displayName() ?? ""
        let wifeName = fam.wife(in: index)?.displayName() ?? ""
        return "\(husbName) + \(wifeName)"
    }
}
