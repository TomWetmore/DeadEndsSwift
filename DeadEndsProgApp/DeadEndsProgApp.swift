//
//  DeadEndsProgApp.swift
//  DeadEndsProgApp
//
//  Created by Thomas Wetmore on 28 May 2026.
//  Last changed on 29 May 2026.
//

import SwiftUI

@main
struct DeadEndsRunnerApp: App {

    @State private var wrappedModel = WrappedModel()

    var body: some Scene {
        
        WindowGroup {
            ProgramPage(
                model: wrappedModel.programModel,
                database: wrappedModel.database
            ) {
                HStack(spacing: 6) {
                    Button("Load Database") {
                        wrappedModel.loadDatabase()
                    }//.buttonStyle(.borderless)

                    Circle()
                        .fill(wrappedModel.database == nil ? .gray : .green)
                        .frame(width: 11, height: 11)
                        .help(wrappedModel.database == nil ? "No database loaded" : "Database loaded")
                }
            }
        }
    }
}
