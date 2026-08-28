//
//  EditPersonSheet.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 16 July 2025.
//  Last changed on 28 August 2026.
//

import SwiftUI
import DeadEndsLib

/// PersonEditSheet is used as a sheet to edit Person Gedcom records. Records are converted
/// to text and edited with a TextEditor. When editing is done the text is parsed into a
/// Gedcom tree and validated. If the user selects to save the changes, the new Person replaces
/// the original in the Database.
///
/// The name should be changed as this does not need to be a Sheet.

struct PersonEditSheet: View {

    @State private var editedText: String
    @State private var showEditAlert: Bool = false
    @State private var editErrors: [String] = []
    @State private var showErrorSheet: Bool = false
    @Environment(AppModel.self) var model
    @Environment(\.dismiss) var dismiss

    let person: Person  // Person edited.

    /// Create a person edit sheet.
    init(person: Person) {

        self.person = person
        _editedText = State(initialValue: person.gedcomText(indent: true))
    }

    private func presentErrorSheet(errors: [String]) {
        editErrors = errors
        showErrorSheet = true
    }

    var body: some View {
        
        VStack(spacing: 8) {

            HStack {
                Text("Editing \(person.displayName())")
                    .font(.headline)
                Spacer()
                Button("Cancel") { // Cancel the editing session.
                    dismiss()
                }
                Button("Save") {
                    handleSave()  // Attempt to save the edited person.
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
        .alert("Edit Error", isPresented: $showEditAlert) {
            Button("Cancel", role: .cancel) {
                dismiss()
            }
            Button("Re-edit") { // Do nothing; return to the view.
            }
        } message: {
            Text("The edited record must contain exactly one record.")
        }
        .sheet(isPresented: $showErrorSheet) {
            ErrorSheet(errors: editErrors, onCancel: {
                dismiss()  // Cancel the error sheet and edit view.
            }, onReedit: {
                showErrorSheet = false  // Close error sheet and allow re-edit
            })
        }
    }

    /// Handle the Save button. Parses text into a record; validates; replaces old person with new.
    func handleSave() {

        let database = model.database!
        let errors = updatePerson(oldPerson: person, newString: editedText, in: database)
        if !errors.isEmpty {
            presentErrorSheet(errors: errors)
            return
        }
        if model.path.count > 0 {
            model.path.removeLast()
            model.path.append(Route.person(person))
        }
        dismiss()
    }
}

struct ErrorSheet: View {
    let errors: [String]
    let onCancel: () -> Void
    let onReedit: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Edit Errors")
                .font(.headline)

            ScrollView {
                ForEach(errors, id: \.self) { err in
                    Text("• \(err)")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
            }
            .frame(minHeight: 200)

            HStack {
                Button("Cancel", role: .cancel) { onCancel() }
                Button("Re-edit") { onReedit() }
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}
