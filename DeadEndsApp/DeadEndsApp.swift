//
//  DeadEndsApp
//  DeadEndsApp.swift
//
//  Created by Thomas Wetmore on 20 June 2025.
//  Last changed on 7 January 2026.
//

import SwiftUI
import DeadEndsLib

/// DeadEnds SwiftUI Application.
@main
struct DeadEndsApp: App {

    // System wide application model injected into the environment.
    @StateObject private var model = AppModel()

    /// Not required -- for debugging.
    init() {
        print("DeadEndsApp init")
    }

    /// Application's Scene.
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
