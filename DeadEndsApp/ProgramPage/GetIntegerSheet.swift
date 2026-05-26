//
//  GetIntegerSheet.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 24 May 2026.
//  Last changed on 24 May 2026.
//

import SwiftUI

/// Integer request sheet used on the program page when a program calls
/// the getinteger built-in.
struct GetIntegerSheet: View {
    let request: GetIntegerRequest
    let onChoose: (Int) -> Void
    let onCancel: () -> Void

    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(request.prompt)
                .font(.headline)

            TextField("Integer", text: $text)
                .textFieldStyle(.roundedBorder)
                .onSubmit(submit)

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                Button("OK", action: submit)
                    .disabled(Int(text) == nil)
            }
        }
        .padding()
        .frame(minWidth: 320)
    }

    private func submit() {
        if let value = Int(text) {
            onChoose(value)
        }
    }
}

struct GetStringSheet: View {
    let request: GetStringRequest
    let onChoose: (String) -> Void
    let onCancel: () -> Void

    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(request.prompt)
                .font(.headline)

            TextField("Integer", text: $text)
                .textFieldStyle(.roundedBorder)
                .onSubmit(submit)

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                Button("OK", action: submit)
                    .disabled(Int(text) == nil)
            }
        }
        .padding()
        .frame(minWidth: 320)
    }

    private func submit() {
        //if let value = text {
            onChoose(text)
        //}
    }
}
