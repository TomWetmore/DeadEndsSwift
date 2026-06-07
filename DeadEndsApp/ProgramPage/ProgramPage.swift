//
//  ProgramPage.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 April 2026.
//  Last changed on 3 June 2026.
//
//  This is the programming page of the app. It allows users to
//  compose, edit, compile and run DeadEnds programs.
//

import SwiftUI
import DeadEndsLib

/// Provides a mini-IDE for the development of DeadEnds programs.
struct ProgramPage<ExtraCommands: View>: View {

    @Bindable var model: ProgramModel
    let database: Database?
    let extraCommands: ExtraCommands

    init(model: ProgramModel, database: Database?,
         @ViewBuilder extraCommands: () -> ExtraCommands = { EmptyView() }) {
            self.model = model
            self.database = database
            self.extraCommands = extraCommands()
        }

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
                    database: database!,
                    onChoose: { model.finishGetPerson($0) },
                    onCancel: { model.finishGetPerson(nil) }
                )

            case .getInteger(let request):
                GetIntegerSheet(
                    request: request,
                    onChoose: { model.finishGetInteger($0) },
                    onCancel: { model.finishGetInteger(nil) }
                )
            case .getString(let request):
                GetStringSheet(
                    request: request,
                    onChoose: { model.finishGetString($0) },
                    onCancel: { model.finishGetString(nil) }
                )
            }
        }
    }

    /// Row of command buttons.
    private var commandBar: some View {
        HStack {

            extraCommands
            HStack {
                Button("Open") {
                    model.openProgramFile()
                }
                StatusCircle(state: model.openState)
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
            HStack {
                Button("Compile") {
                    model.handleCompileButton()
                }
                StatusCircle(state: model.compileState)
            }
            .disabled(model.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            HStack {
                Button("Run") {
                    if let db = database {
                        Task {
                            await model.handleRunButton(database: db)
                        }
                    }
                }
                StatusCircle(state: model.runState)
            }
            .disabled(model.parsedProgram == nil || database == nil)
            Spacer()
        }
        .buttonStyle(.borderless)
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
        //TextEditor(text: $model.source)
        CodeEditor(text: $model.source)
            .font(.system(size: 16, design: .monospaced))
            .padding(8)
            .onChange(of: model.source) { _, _ in
                model.sourceWasEdited()
            }
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


