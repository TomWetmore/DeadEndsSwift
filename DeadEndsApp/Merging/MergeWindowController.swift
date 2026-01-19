//
//  MergeWindowController.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 7 November 2025.
//  Last changed on 3 January 2026.
//

import SwiftUI
import AppKit
import DeadEndsLib

/// Transient state for an active merge operation. Holds the coordinates of the GedcomNodes that are
/// visible in the central merge pane.

final class MergeSession: ObservableObject {

    init() {}
}

#if os(macOS)   // Ensure AppKit code is not loaded on other platforms,

@MainActor
enum MergeWindowController {

    static func open(left: Person, right: Person) {
        let host = MergeWindowHost(left: left, right: right)
        host.present()
    }
}

@MainActor
private final class MergeWindowHost: NSWindowController, NSWindowDelegate {

    private static var living: Set<ObjectIdentifier> = []

    private let left: Person
    private let right: Person

    init(left: Person, right: Person) {
        self.left = left
        self.right = right

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered, defer: false
        )

        window.title = "Merge Records"
        window.center()

        super.init(window: window)

        window.delegate = self
        window.contentView = NSHostingView(
            rootView: MergeWindow(left: left, right: right) {
                self.window?.performClose(nil)
            }
        )
    }

    required init?(coder: NSCoder) { fatalError() }

    func present() {
        window?.makeKeyAndOrderFront(nil)
        Self.living.insert(ObjectIdentifier(self))
    }

    func windowWillClose(_ notification: Notification) {
        Self.living.remove(ObjectIdentifier(self))
    }
}

#endif
