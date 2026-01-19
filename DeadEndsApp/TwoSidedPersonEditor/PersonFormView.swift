//
//  PersonFormView.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 22 September 2025.
//  Last changed on 26 September 2025.
//

import SwiftUI
import DeadEndsLib

struct PersonFormView: View {
    @ObservedObject var vm: PersonEditorViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // MARK: Name and Sex
                GroupBox(label: Text("Name and Sex").font(.headline)) {
                    TextField("Full Name", text: $vm.name)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { vm.rebuildGedcomTree() }

                    Picker("Sex", selection: $vm.sex) {
                        Text("Unknown").tag(SexType?.some(.unknown))
                        Text("Male").tag(SexType?.some(.male))
                        Text("Female").tag(SexType?.some(.female))
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: vm.sex) { _, _ in
                        vm.rebuildGedcomTree()
                    }
                }

                // MARK: Birth
                GroupBox(label: Text("Birth").font(.headline)) {
                    TextField("Date", text: $vm.birthDate)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { vm.rebuildGedcomTree() }

                    TextField("Place", text: $vm.birthPlace)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { vm.rebuildGedcomTree() }
                }

                // MARK: Death Toggle
                Toggle("Include Death", isOn: $vm.showDeath)
                    .onChange(of: vm.showDeath) { _, _ in
                        vm.rebuildGedcomTree()
                    }

                // MARK: Death
                if vm.showDeath {
                    GroupBox(label: Text("Death").font(.headline)) {
                        TextField("Date", text: $vm.deathDate)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { vm.rebuildGedcomTree() }

                        TextField("Place", text: $vm.deathPlace)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { vm.rebuildGedcomTree() }
                    }
                }

                // MARK: Future: Dynamic Event Handling
//                ForEach(vm.customEvents) { event in
//                    GroupBox(label: Text(event.label).font(.headline)) {
//                        CustomEventView(event: event)
//                    }
//                }

                Button("Add Event") {
                    vm.addNewEvent()
                }
                .padding(.horizontal)

                // MARK: Reset Button
                Button("Reset Form") {
                    vm.clear()
                }
                .padding(.horizontal)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}
