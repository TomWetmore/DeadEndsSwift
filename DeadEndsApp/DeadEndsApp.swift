//
//  DeadEndsApp
//  DeadEndsApp.swift
//
//  Created by Thomas Wetmore on 20 June 2025.
//  Last changed on 17 January 2026.
//

import SwiftUI
import DeadEndsLib

/// DeadEnds SwiftUI application.
@main
struct DeadEndsApp: App {

    // System wide application model injected into the environment.
    @StateObject private var model = AppModel()

    /// Application scene.
    var body: some Scene {

        WindowGroup {
            RootView()
                .environmentObject(model)
                .onAppear {
                    print("RootView appearing — PID:", getpid()) // Debug.
                }
                .onDisappear {
                    print("RootView disappearing, terminating app.") // Debug.
                    NSApplication.shared.terminate(nil)
                }
        }
    }
}
