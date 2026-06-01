//
//  PersonFormNew.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 1 October 2025.
//  Last changed on 1 October 2025.
//

import SwiftUI
import DeadEndsLib

struct PersonFormNew: View {
    @ObservedObject var viewModel: PersonEditorViewModelNew

    var body: some View {
        Form {
            Section(header: Text("Person Vitals")) {
                TextField("Name", text: $viewModel.name)

                Picker("Sex", selection: $viewModel.sex) {
                    Text("Male").tag(SexType.male as SexType?)
                    Text("Female").tag(SexType.female as SexType?)
                    Text("Unknown").tag(SexType.unknown as SexType?)
                }

                TextField("Birth Date", text: $viewModel.birthDate)
                TextField("Birth Place", text: $viewModel.birthPlace)

                Toggle("Show Death", isOn: $viewModel.showDeath)
                if viewModel.showDeath {
                    TextField("Death Date", text: $viewModel.deathDate)
                    TextField("Death Place", text: $viewModel.deathPlace)
                }
            }
        }
    }
}
