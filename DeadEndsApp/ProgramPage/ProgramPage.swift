//
//  ProgramPage.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 April 2026.
//  Last changed on 23 April 2026.
//
//  This is the programming page of the app. It allows users to
//  compose, edit, compile and run DeadEnds programs.
//


import SwiftUI

struct ProgramPage: View {

    @EnvironmentObject var appModel: AppModel
    @Bindable var model: ProgramModel

    var body: some View {
        VStack(spacing: 0) {

            TextEditor(text: $model.source)  // Editor for DeadEnds programs.
                .font(.system(.body, design: .monospaced))
                .padding(8)

            Divider()

            HStack {  // Button bar.
                Button("Compile") {  // Button that compiles the program.
                    model.compile()
                }
                .disabled(model.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("Run") {  // Button that runs the program.
                    if let db = appModel.database {
                        model.run(database: db)
                    }
                }
                .disabled(model.parsedProgram == nil || appModel.database == nil)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            ScrollView {  // View that shows the program output.
                Text(model.output.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            DiagnosticsPane(diagnostics: model.diagnostics)  // Pane that shows errors.
                .frame(minHeight: 120, idealHeight: 160)
                .padding(8)
        }
        .navigationTitle(model.programName)
    }
}
