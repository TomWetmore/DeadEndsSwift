//
//  FamilySelectionSheet.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 14 July 2025.
//  Last changed on 15 September 2025.
//

import SwiftUI
import DeadEndsLib

// FamilySelectionSheet allows the user to select among families represented as an array
// of Families.
struct FamilySelectionSheet: View {
    let families: [Family] // Array of FAM GedcomNodes
    let onSelect: (Family) -> Void // Closure to call on selected FAM node.

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

    func familySummary(_ fam: Family, index: RecordIndex) -> String {
        let husbName = fam.husband(in: index)?.displayName() ?? ""
        let wifeName = fam.wife(in: index)?.displayName() ?? ""
        print("husband's name is \(husbName)")
        return "\(husbName) + \(wifeName)"
    }
}
