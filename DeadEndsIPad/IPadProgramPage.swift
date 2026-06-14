//
//  IPadProgramPage.swift
//  DeadEndsIPad
//
//  Created by Thomas Wetmore on 13 June 2026.
//  Last changed on 13 June 2026.
//

import SwiftUI

struct IPadProgramPage: View {

    @Bindable var model: IPadRunnerModel

    var body: some View {
        VStack(spacing: 0) {

            HStack {
                Button("Load Database") {
                    model.showingDatabaseImporter = true
                }
                StatusCircle(state: model.databaseState)

                Button("Load Program") {
                    model.showingProgramImporter = true
                }
                StatusCircle(state: model.programModel.openState)

                Button("Compile") {
                    model.programModel.handleCompileButton()
                }
                .disabled(model.programModel.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                StatusCircle(state: model.programModel.compileState)

                Button("Run") {
                    if let db = model.database {
                        Task {
                            await model.programModel.handleRunButton(database: db)
                        }
                    }
                }
                .disabled(model.programModel.parsedProgram == nil || model.database == nil)

                StatusCircle(state: model.programModel.runState)

                Spacer()
            }
            .padding()

            TextEditor(text: $model.programModel.source)
                .font(.system(size: 16, design: .monospaced))
                .padding()
                .onChange(of: model.programModel.source) { _, _ in
                    model.programModel.sourceWasEdited()
                }

            Divider()

            ScrollView {
                Text(model.programModel.output.text)
                    .font(.system(size: 16, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .textSelection(.enabled)
            }
        }
        .fileImporter(
            isPresented: $model.showingProgramImporter,
            allowedContentTypes: [.plainText, .data]
        ) { result in
            if case .success(let url) = result {
                model.loadProgram(from: url)
            }
        }
        .fileImporter(
            isPresented: $model.showingDatabaseImporter,
            allowedContentTypes: [.data]
        ) { result in
            if case .success(let url) = result {
                model.loadDatabase(from: url)
            }
        }
    }
}
