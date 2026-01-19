//
//  SelectableCard.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 17 January 2026.
//  Last changed on 19 January 2026.
//

import SwiftUI

struct SelectableCard<Content: View>: View {

    @Bindable var model: DesktopModel
    let cardID: UUID
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture { handleTap() }
    }

    private func handleTap() {
        print("handle tap")
        model.bringToFront(cardID)
        // macOS: use AppKit to read the modifier keys.
        let flags = NSApp.currentEvent?.modifierFlags ?? []

        if flags.contains(.command) || flags.contains(.shift) {
            toggle()
        } else {
            selectOnly()
        }
    }

    private func selectOnly() {
        print("selectOnly")
        if model.selectedIDs.count == 1, model.selectedIDs.contains(cardID) {
            return
        }
        model.selectedIDs = [cardID]
    }

    private func toggle() {
        print("toggle")
        if model.selectedIDs.contains(cardID) {
            model.selectedIDs.remove(cardID)
        } else {
            model.selectedIDs.insert(cardID)
        }
    }
}
