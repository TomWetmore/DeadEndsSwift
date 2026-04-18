//
//  ProgramPage.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 April 2026.
//  Last changed on 15 April 2026.
//

import SwiftUI

struct ProgramPage: View {
    @Bindable var model: ProgramModel
    let compiler: ProgramCompiler

    var body: some View {
        VStack(spacing: 0) {
            toolbar

            Divider()

            VStack(spacing: 0) {
                editorPane

                Divider()

                DiagnosticsPane(diagnostics: model.compileDiagnostics)
                    .frame(minHeight: 160, idealHeight: 220)
            }
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
        TextEditor(text: $model.sourceText)
            .font(.system(.body, design: .monospaced))
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func compileProgram() {
        let result: CompileResult = compiler.compile(source: model.sourceText)
        model.applyCompileResult(result)
    }
}

#Preview {
    NavigationStack {
        ProgramPage(
            model: ProgramModel(
                programName: "Ancestors Report",
                sourceText:
"""
proc main ()
{
    set(i, getindi("Enter person"))
    ERROR
    WARNING
}
"""
            ),
            compiler: MockProgramCompiler()
        )
    }
    .frame(width: 900, height: 650)
}
