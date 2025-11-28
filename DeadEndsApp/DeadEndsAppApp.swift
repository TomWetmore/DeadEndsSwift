//
//  DeadEndsApp
//  DeadEndsApp.swift
//
//  Created by Thomas Wetmore on 20 June 2025.
//  Last changed on 13 November 2025.
//

import SwiftUI
import DeadEndsLib

@main
struct DeadEndsApp: App {

    @StateObject private var model = AppModel()

    init() {
        print("DeadEndsApp init")  // DEBUG
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .onAppear {
                    print("DeadEndsApp launched — PID:", getpid()) // DEBUG
                }
                .onDisappear {
                    print("RootView disappearing, terminating app.") // DEBUG
                    NSApplication.shared.terminate(nil)
                }
        }
    }
}
