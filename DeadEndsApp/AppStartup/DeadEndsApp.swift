//
//  DeadEndsApp
//  DeadEndsApp.swift
//
//  Created by Thomas Wetmore on 20 June 2025.
//  Last changed on 7 March 2026.

/// DeadEndsApp is the MacOS DeadEnds application. It creates AppModel, the
/// system wide application model and then renders the root view. The model
/// is put in the view hierarchy to for universal accessibility.

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
                .onAppear { print("RootView appear — pid:", getpid()) }  // Debug.
                .onDisappear {
                    print("RootView disappear, app terminate.")  // Debug.
                    NSApplication.shared.terminate(nil)
                }
        }
    }
}
