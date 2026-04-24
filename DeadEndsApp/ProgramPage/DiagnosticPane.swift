//
//  DiagnosticPane.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 April 2026.
//  Last changed on 23 April 2026.
//

import SwiftUI

struct DiagnosticsPane: View {
    let diagnostics: [Diagnostic]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if diagnostics.isEmpty {
                Text("No diagnostics")
                    .italic()
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(diagnostics.enumerated()), id: \.offset) { _, diag in
                    Text(format(diag))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(8)
    }

    private func format(_ diag: Diagnostic) -> String {
        if let line = diag.line {
            return "Line \(line): \(diag.message)"
        } else {
            return diag.message
        }
    }
}
