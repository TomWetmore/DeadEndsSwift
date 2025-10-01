//
//  EditPersonView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 16 July 2025.
//  Last changed on 15 September 2025.
//

import SwiftUI
import DeadEndsLib

// PersonEditView is used as a sheet to edit Person Gedcom records.
struct PersonEditSheet: View {

    @State private var editedText: String
    @State private var showEditAlert: Bool = false
    @State private var editErrors: [String] = []
    @State private var showErrorSheet: Bool = false
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) var dismiss

    let person: Person

    /// Initializes a PersonEditView
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
            Button("Re-edit") {
                // Do nothing, just return to the view
            }
        } message: {
            Text("The edited record must contain exactly one record.")
        }
        .sheet(isPresented: $showErrorSheet) {
            ErrorSheet(errors: editErrors, onCancel: {
                dismiss()  // cancel both error sheet and edit view
            }, onReedit: {
                showErrorSheet = false  // just close the error sheet and allow re-edit
            })
        }
    }

    /// Handles the Save button push on the EditPersonView.
    ///
    /// Parses the text into a new record; validates the edited person; and replaces
    /// the old person with the new.
    ///
    func handleSave() {

        // Parse the edited text into a Person record. This may fail.
        var (editedPerson, errors) = parsePerson(text: editedText)
        if errors.count > 0 {
            presentErrorSheet(errors: errors)
            return
        }
        // Get PersonInfo for the two versions of the Person. There may be errors.
        let (old, _) = getPersonInfo(for: self.person)
        let (new, extractErrors) = getPersonInfo(for: editedPerson!)
        
        // Initialze errors with those found while extracting the new PersonInfo.
        errors.append(contentsOf: extractErrors)

        // Validate the edited person (may add more errors)
        let recordIndex = model.database!.recordIndex
        errors.append(contentsOf: validateEditedPerson(old: old, new: new, index: recordIndex))

        // If any errors were found show them and present the error sheet.
        if !errors.isEmpty {
            presentErrorSheet(errors: errors)
            return
        }

        // Update the person and refresh the PersonView with the changes.
        applyPersonUpdates(old: old, new: new)
        if model.path.count > 0 {
            model.path.removeLast()
            model.path.append(Route.person(person))
        }

        // Close the edit sheet
        dismiss()
    }
}

extension PersonEditSheet {

    /// Parses edited text into a Person record. Returns nil and error list if there are errors.
    func parsePerson(text: String) -> (edited: Person?, errors: [String]) {
        
        let source = StringGedcomSource(name: "edit view", content: text)
        var errlog = ErrorLog()
        var tagmap = model.database!.tagmap

        guard let nodes = loadRecords(from: source, tagMap: &tagmap, errlog: &errlog) else {
            return (nil, ["Error parsing record"])
        }
        if errlog.count > 0 { return (nil, ["Error parsing record"]) }
        guard nodes.count == 1 else { return (nil, ["Found \(nodes.count) records"]) }
        guard let person = Person(nodes[0]) else { return (nil, ["The record is not a Person (INDI)"]) }
        return (person, [])
    }

    /// Validates an edited Person record.
    func validateEditedPerson(old: PersonInfo, new: PersonInfo, index: RecordIndex) -> [String] {

        var problems: [String] = []
        // Person must have at least one NAME line with value.
        if new.names.isEmpty {
            problems.append("Edited person must have at least one NAME.")
        }
        // New Person should have a SEX value that is consistent with his/her role in the FAMS families.
//        if let sex = new.sex {
//            for famKey in new.famsKeys {
//                guard let fam = index[famKey] else { continue }
//                let ( _, husb, wife, _, _) = splitFamily(fam: fam)
//                if sex == "M" && !containsPointer(to: old.key, in: husb) {
//                    problems.append("SEX is M, but person is not HUSB in FAMS family \(famKey).")
//                }
//                if sex == "F" && !containsPointer(to: old.key, in: wife) {
//                    problems.append("SEX is F, but person is not WIFE in FAMS family \(famKey).")
//                }
//            }
//        }
        // Edited Person must have the same FAMC and FAMS values, though they may be reordered.
        if old.famcKeys != new.famcKeys {
            problems.append("FAMC lines cannot be changed, only reordered")
        }
        if old.famsKeys != new.famsKeys {
            problems.append("FAMS lines cannot be changed, only reordered")
        }
        // All cross-references in new record must refer to existing records
        let allPointers = new.root.root.descendants()
            .compactMap { $0.val }
            .filter { $0.hasPrefix("@") && $0.hasSuffix("@") }
        for key in allPointers {
            if index[key] == nil {
                problems.append("Pointer to nonexistent record: @\(key)@.")
            }
        }
        return problems
    }

    /// Updates the Database after successfully editing a Person.
    func applyPersonUpdates(old: PersonInfo, new: PersonInfo) {

        let db = model.database!

        // Update NameIndex
        let addedNames = new.names.subtracting(old.names)
        let removedNames = old.names.subtracting(new.names)
        for name in removedNames { db.nameIndex.remove(value: name, recordKey: old.key) }
        for name in addedNames { db.nameIndex.add(value: name, recordKey: old.key) }

        // Update RefnIndex (when implemented)
        let addedRefns = new.refns.subtracting(old.refns)
        let removedRefns = old.refns.subtracting(new.refns)
        for refn in removedRefns { db.refnIndex.remove(refn: refn) }
        for refn in addedRefns { db.refnIndex.add(refn: refn, key: old.key) }

        // Update the database with the edited person keeping the same Person root.
        old.root.root.replaceChildren(with: new.root.kid)
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

/// Structure holding Person information.
struct PersonInfo {
    let root: Person
    let key: String
    let sex: String?
    let names: Set<String>
    let famcKeys: Set<String>
    let famsKeys: Set<String>
    let refns: Set<String>
}

/// Extracts the PersonInfo of a Person record.
///
/// The internal structure (`child`, `sibling` and `parent` links) of the Person is not affected.
func getPersonInfo(for person: Person) -> (info: PersonInfo, errors: [String]) {
    var names: Set<String> = []
    var refns: Set<String> = []
    var sex: String? = nil
    var famcKeys: Set<String> = []
    var famsKeys: Set<String> = []
    var errors: [String] = []

    var current = person.kid
    while let node = current {
        let tag = node.tag
        if let value = node.val, !value.isEmpty {
            switch tag {
            case "NAME": names.insert(value)
            case "SEX":
                if sex == nil { sex = value }
                else { errors.append("Multiple SEX tags found.") }
            case "REFN": refns.insert(value)
            case "FAMC": famcKeys.insert(value)
            case "FAMS": famsKeys.insert(value)
            default: break
            }
        } else if ["NAME", "SEX", "REFN", "FAMC", "FAMS"].contains(tag) {
            errors.append("Missing value for \(tag) line.")
        }
        current = node.sib
    }

    // Construct PersonInfo even if there are errors
    let info = PersonInfo(
        root: person,
        key: person.key,
        sex: sex,
        names: names,
        famcKeys: famcKeys,
        famsKeys: famsKeys,
        refns: refns
    )
    return (info, errors)
}
