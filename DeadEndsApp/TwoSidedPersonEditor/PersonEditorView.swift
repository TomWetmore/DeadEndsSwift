//
//  PersonEditorView.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 22 September 2025.
//  Last changed on 26 September 2025.
//

import SwiftUI
import DeadEndsLib

/// Two sided View for Editing (and creating) Persons.
struct PersonEditorView: View {

    // A @StateObject is typically a view model (class objects) owned by the view.
    @StateObject var vm: PersonEditorViewModel
    let onSave: (Person) -> Void  // Action to take; a closure parameter to the initializer.

    init(person: Person, onSave: @escaping (Person) -> Void) {
        _vm = StateObject(wrappedValue: PersonEditorViewModel(person: person))
        self.onSave = onSave
    }

    var body: some View {
        VStack {
            HSplitView {
                PersonFormView(vm: vm)
                    .frame(minWidth: 200, idealWidth: 300, maxWidth: .infinity, alignment: .leading)
                    .padding()
                GedcomTreeView(root: vm.person, expandedNodes: $vm.expanded)
                    .frame(minWidth: 200, idealWidth: 300, maxWidth: .infinity, alignment: .leading)
                    .padding()
            }

            Divider()

            HStack {
                Spacer()
                Button("Save") {
                    vm.rebuildGedcomTree()
                    onSave(vm.person)
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
    }
}
