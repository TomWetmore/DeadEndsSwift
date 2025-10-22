//
//  PersonEditorViewNew.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 1 October 2025.
//  Last changed on 1 October 2025.
//

import SwiftUI
import DeadEndsLib

struct PersonEditorViewNew: View {

    @StateObject private var viewModel: PersonEditorViewModelNew
    let onSave: (Person) -> Void  // Action to take; a closure parameter to the initializer.

    init(person: Person, onSave: @escaping (Person) -> Void) {
        _viewModel = StateObject(wrappedValue: PersonEditorViewModelNew(person: person))
        self.onSave = onSave
    }

    var body: some View {
        VStack {
            // Top form
            PersonFormNew(viewModel: viewModel)
                .frame(height: 300)

            Divider()

            // Bottom tree editor
            ScrollView {
                GedcomTreeViewNew(viewModel: viewModel, node: viewModel.root)
                    .padding()
            }
        }
        .navigationTitle("Edit Person (Newer)")
    }
}
