//
//  MockProgramCompiler.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 4/15/26.
//

import Foundation

struct MockProgramCompiler: ProgramCompiler {

    func compile(source: String) -> CompileResult {
        var diagnostics: [Diagnostic] = []

        let lines = source.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1

            if line.contains("ERROR") {
                diagnostics.append(
                    Diagnostic(
                        kind: .syntax,
                        severity: .error,
                        message: "Mock syntax error triggered by the token ERROR.",
                        location: SourceLocation(line: lineNumber)
                    )
                )
            }

            if line.contains("WARNING") {
                diagnostics.append(
                    Diagnostic(
                        kind: .semantic,
                        severity: .warning,
                        message: "Mock warning triggered by the token WARNING.",
                        location: SourceLocation(line: lineNumber)
                    )
                )
            }
        }

        if diagnostics.contains(where: { $0.severity == .error }) {
            return CompileResult(program: nil, diagnostics: diagnostics)
        } else {
            return CompileResult(program: source, diagnostics: diagnostics)
        }
    }
}
