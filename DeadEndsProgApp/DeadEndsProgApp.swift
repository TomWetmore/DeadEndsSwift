//
//  DeadEndsProgApp.swift
//  DeadEndsProgApp
//
//  Created by Thomas Wetmore on 28 May 2026.
//  Last changed on 3 June 2026.
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
                    }
                    StatusCircle(state: wrappedModel.databaseState)
                }
            }
        }
        .commands {
            CommandGroup(after: .textEditing) {
                Button("Find…") {
                    NSApp.sendAction(
                        #selector(NSTextView.performFindPanelAction(_:)),
                        to: nil,
                        from: nil
                    )
                }
                .keyboardShortcut("f", modifiers: .command)
            }
        }
    }
}
