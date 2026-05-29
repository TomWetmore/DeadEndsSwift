//
//  DeadEndsProgApp.swift
//  DeadEndsProgApp
//
//  Created by Thomas Wetmore on 28 May 2026.
//  Last changed on 28 May 2026.
//

import SwiftUI


@main
struct DeadEndsRunnerApp: App {
    @State private var model = WrappedModel()

    var body: some Scene {
        WindowGroup {
            ProgramPage(model: model.programModel, database: model.database)
        }
    }
}
