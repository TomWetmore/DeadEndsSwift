//
//  DeadEndsApp
//  DeadEndsApp.swift
//
//  Created by Thomas Wetmore on 20 June 2025.
//  Last changed on 17 July 2025.
//

import SwiftUI
import DeadEndsLib

@main
struct DeadEndsApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .onDisappear {
                    NSApplication.shared.terminate(nil)
                }
        }
    }
}
