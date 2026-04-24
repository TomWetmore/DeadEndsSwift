//
//  ProgramPage.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 April 2026.
//  Last changed on 21 April 2026.
//

import SwiftUI

//
//  ProgramPage.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 April 2026.
//  Last changed on 23 April 2026.
//

import SwiftUI

struct ProgramPage: View {

    @EnvironmentObject var appModel: AppModel
    @Bindable var model: ProgramModel

    var body: some View {
        VStack(spacing: 0) {

            TextEditor(text: $model.source)
                .font(.system(.body, design: .monospaced))
                .padding(8)

            Divider()

            HStack {
                Button("Compile") {
                    model.compile()
                }
                .disabled(model.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("Run") {
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

            ScrollView {
                Text(model.output.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            DiagnosticsPane(diagnostics: model.diagnostics)
                .frame(minHeight: 120, idealHeight: 160)
                .padding(8)
        }
        .navigationTitle(model.programName)
    }
}

#Preview {
    NavigationStack {
        ProgramPage(
            model: ProgramModel(
                programName: "Ancestors Report",
                source:
"""
proc main ()
{
    set(i, getindi("Enter person"))
}
"""
            )
        )
    }
    .frame(width: 900, height: 650)
}
