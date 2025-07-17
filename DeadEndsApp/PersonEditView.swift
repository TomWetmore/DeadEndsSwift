//
//  EditPersonView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 16 July 2025.
//  Last changed on 16 July 2025
//

import SwiftUI
import DeadEndsLib

// PersonEditView is used as a sheet to edit Person Gedcom records.
struct PersonEditView: View {
    @State private var editedText: String
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) var dismiss
    let person: GedcomNode

    // init initializes a PersonEditView
    init(person: GedcomNode) {
        self.person = person
        _editedText = State(initialValue: person.gedcomText(indent: true))
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Editing \(person.displayName())")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("Save") {
                    // TODO: parse editedText back into a GedcomNode and update database
                    dismiss()
                }
            }
            .padding(.horizontal)

            Divider()

            TextEditor(text: $editedText)
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 600, minHeight: 400)
                .padding()
        }
        .padding()
    }
    func handleSave() {
        // Step 1: Parse edited text → GNode tree
        // Step 2: Validate (especially linkage tags)
        // Step 3: Replace originalNode’s contents (but preserve its pointer identity)
        // Step 4: Update model.database indexes (by key and by name)
        dismiss()
    }
}
