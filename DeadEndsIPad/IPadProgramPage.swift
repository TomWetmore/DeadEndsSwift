//
//  IPadProgramPage.swift
//  DeadEndsIPad
//
//  Created by Thomas Wetmore on 13 June 2026.
//  Last changed on 16 June 2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct IPadProgramPage: View {

    @Bindable var model: IPadRunnerModel
    @State private var showingImporter = false
    @State private var importKind: ImportKind?

    var body: some View {
        VStack(spacing: 0) {

            HStack {
                Button("Load Database") {
                    importKind = .database
                    showingImporter = true
                }
                StatusCircle(state: model.databaseState)

                Button("Load Program") {
                    importKind = .program
                    showingImporter = true
                }
                StatusCircle(state: model.programLoadState)

                Button("Compile") {
                    model.handleCompileButton()
                }
                .disabled(model.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                StatusCircle(state: model.compileState)

                Button("Run") {
                    if let db = model.database {
                        Task {
                            await model.handleRunButton(database: db)
                        }
                    }
                }
                .disabled(model.parsedProgram == nil || model.database == nil)
                StatusCircle(state: model.runState)

                Spacer()
            }
            .padding()

            TextEditor(text: $model.source)
                .font(.system(size: 16, design: .monospaced))

            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding()
            .onChange(of: model.source) { _, _ in
                model.sourceWasEdited()
            }

            /*
             TextEditor(text: $model.source)
                 .font(.system(.body, design: .monospaced))
                 .textInputAutocapitalization(.never)
                 .autocorrectionDisabled()
             */

            Divider()

            ScrollView {
                Text(model.output.text)
                    .font(.system(size: 16, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .textSelection(.enabled)
            }
        }
        .sheet(item: $model.programRequest) { request in
            switch request {
            case .getPerson(let request):
                GetPersonSheet(
                    request: request,
                    database: model.database!,
                    onChoose: { person in
                        model.finishGetPerson(person)
                    },
                    onCancel: {
                        model.finishGetPerson(nil)
                    }
                )

            case .getInteger(let request):
                VStack(spacing: 20) {
                    Text(request.prompt)
                    Button("Return 42") {
                        //model.finishGetInteger(42)
                    }
                    Button("Cancel") {
                        //model.finishGetInteger(nil)
                    }
                }
                .padding()

            case .getString(let request):
                VStack(spacing: 20) {
                    Text(request.prompt)
                    Button("Return test string") {
                        //model.finishGetString("test string")
                    }
                    Button("Cancel") {
                        //model.finishGetString(nil)
                    }
                }
                .padding()
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.plainText, .data]
        ) { result in
            guard let importKind else { return }
            self.importKind = nil

            if case .success(let url) = result {
                switch importKind {
                case .database:
                    model.loadDatabase(from: url)
                case .program:
                    model.loadProgram(from: url)
                }
            }
        }
    }
}

enum ImportKind {
    case database
    case program
}
