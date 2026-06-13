//
//  DeadEndsIPadApp.swift
//  DeadEndsIPad
//
//  Created by Thomas Wetmore on 28 January 2026.
//  Last changed on 13 June 2026.
//

import SwiftUI

@main
struct DeadEndsIPadApp: App {

    @State private var model = IPadRunnerModel()

    var body: some Scene {
        WindowGroup {
            IPadProgramPage(model: model)
        }
    }
}
