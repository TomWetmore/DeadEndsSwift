//
//  ProgramPage.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 April 2026.
//  Last changed on 21 April 2026.
//

import SwiftUI

struct ProgramPage: View {
    
    @EnvironmentObject var appModel: AppModel
    @Bindable var model: ProgramModel
    //let compiler: ProgramCompiler

    var body: some View {
        VStack(spacing: 0) {

            TextEditor(text: $model.source)

            HStack {
                Button("Compile") {
                    model.compile()
                }
                Button("Run") {
                    if let db = appModel.database {
                        model.run(database: db)
                    }
                }
                .disabled(model.compiledProgram == nil)
            }

            Divider()
            ScrollView {
                Text(model.output.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            Divider()

            DiagnosticsPane(diagnostics: model.compileDiagnostics)
                .frame(minHeight: 160, idealHeight: 220)

        }
        .navigationTitle(model.programName)
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Text(model.programName)
                .font(.headline)

            Spacer()

            if model.lastCompileSucceeded {
                Text("Compiled")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            Button("Compile") {
                compileProgram()
            }
            .keyboardShortcut("b", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var editorPane: some View {
        TextEditor(text: $model.source)
            .font(.system(.body, design: .monospaced))
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func compileProgram() {
        let result: CompileResult = ProgramCompiler.compile(source: model.source)
        model.applyCompileResult(result)
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
    ERROR
    WARNING
}
"""
            ),
            compiler: ProgramCompiler()
        )
    }
    .frame(width: 900, height: 650)
}
