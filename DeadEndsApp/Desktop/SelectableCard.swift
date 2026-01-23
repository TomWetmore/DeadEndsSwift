//
//  SelectableCard.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 17 January 2026.
//  Last changed on 20 January 2026.
//

import SwiftUI

/// Implements selectable behavior; rendering of selection done in CardView.
struct SelectableCard<Content: View>: View {

    @Bindable var model: DesktopModel
    let cardID: UUID
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture { handleTap() }
    }

    /// Handle selection via tap gesture
    private func handleTap() {
        model.bringToFront(cardID)  // TODO: Needs a little more thought.
        let flags = NSApp.currentEvent?.modifierFlags ?? []  // Modifier keys.
        if flags.contains(.command) || flags.contains(.shift) {
            toggle()
        } else {
            selectOnly()
        }
    }

    private func selectOnly() {
        if model.selectedIDs.count == 1, model.selectedIDs.contains(cardID) {
            return
        }
        model.selectedIDs = [cardID]  // Unselects all others.
    }

    private func toggle() {
        if model.selectedIDs.contains(cardID) {
            model.selectedIDs.remove(cardID)
        } else {
            model.selectedIDs.insert(cardID)
        }
    }
}
