//
//  DeadEndsApp
//  DeadEndsApp.swift
//
//  Created by Thomas Wetmore on 20 June 2025.
//  Last changed on 24 February 2026.
//

import SwiftUI
import DeadEndsLib

/// DeadEnds SwiftUI application.
@main
struct DeadEndsApp: App {

    @StateObject private var model = AppModel()  // System wide application model.

    /// Application scene.
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .onAppear { print("RootView appear — PID:", getpid()) }
                .onDisappear {
                    print("RootView disappear, app terminate.")
                    NSApplication.shared.terminate(nil)
                }
        }
    }
}
