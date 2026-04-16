//
//  DiagnosticPane.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 4/15/26.
//

import SwiftUI

struct DiagnosticsPane: View {
    let diagnostics: [Diagnostic]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            if diagnostics.isEmpty {
                emptyState
            } else {
                List(diagnostics) { diagnostic in
                    DiagnosticRow(diagnostic: diagnostic)
                }
                .listStyle(.plain)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Diagnostics")
                .font(.headline)

            Spacer()

            Text("\(diagnostics.count)")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No diagnostics")
                .font(.body)
            Text("Compile the program to see syntax and semantic errors here.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
}

private struct DiagnosticRow: View {
    let diagnostic: Diagnostic

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(severityLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(severityColor)

                Text(kindLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if let location = diagnostic.location {
                    Text(location.displayString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(diagnostic.message)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }

    private var severityLabel: String {
        diagnostic.severity.rawValue.uppercased()
    }

    private var kindLabel: String {
        diagnostic.kind.rawValue.capitalized
    }

    private var severityColor: Color {
        switch diagnostic.severity {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}
