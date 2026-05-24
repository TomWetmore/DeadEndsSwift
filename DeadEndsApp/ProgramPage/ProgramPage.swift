//
//  ProgramPage.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 April 2026.
//  Last changed on 24 May 2026.
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

            commandBar
            Divider()

            VSplitView {

                textEditor
                outputView
            }
            Divider()
            DiagnosticsPane(diagnostics: model.diagnostics)  // Pane that shows errors.
                .frame(minHeight: 50, idealHeight: 70)
                .padding(8)
        }
        .padding(8)
        .navigationTitle(model.programName)
        .sheet(item: $model.programRequest) { request in
            switch request {
            case .getPerson(let request):
                GetPersonSheet(
                    request: request,
                    database: appModel.database!,
                    onChoose: { model.finishGetPerson($0) },
                    onCancel: { model.finishGetPerson(nil) }
                )

            case .getInteger(let request):
                GetIntegerSheet(
                    request: request,
                    onChoose: { model.finishGetInteger($0) },
                    onCancel: { model.finishGetInteger(nil) }
                )
            }
        }
    }

    /// Row of command buttons.
    private var commandBar: some View {
        HStack {
            Button("Open") {
                model.openProgramFile()
            }
            Button("Save") {
                model.saveProgramFile()
            }
            .disabled(model.source.isEmpty)
            Button("Save As") {
                model.saveProgramFileAs()
            }
            .disabled(model.source.isEmpty)
            Spacer().frame(width: 12)
            Button("Compile") {
                model.handleCompileButton()
            }
            .disabled(model.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Run") {
                if let db = appModel.database {
                    Task {
                        await model.handleRunButton(database: db)
                    }
                }
            }
            .disabled(model.parsedProgram == nil || appModel.database == nil)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(minHeight: 48, idealHeight: 60, maxHeight: 60)
    }

    /// Failed experiment to get line numbers.
    private var poortextEditor: some View {

        HStack(alignment: .top, spacing: 0) {

            ScrollView {
                Text(lineNumbers)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
            .frame(width: 50)

            TextEditor(text: $model.source)
                .font(.system(size: 14, design: .monospaced))
        }
    }

    private var textEditor: some View {

        TextEditor(text: $model.source)  // Editor for DeadEnds programs.
            .font(.system(size: 16, design: .monospaced))
            .padding(8)
    }

    private var outputView: some View {
        ScrollView {  // View that shows the program output.
            Text(model.output.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .textSelection(.enabled)
                .font(.system(size: 16, design: .monospaced))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// This doesn't help.
    private var lineNumbers: String {
        let count = max(model.source.components(separatedBy: "\n").count, 1)

        return (1...count)
            .map { "\($0)" }
            .joined(separator: "\n")
    }
}


