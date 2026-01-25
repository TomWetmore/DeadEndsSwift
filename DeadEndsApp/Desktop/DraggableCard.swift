//
//  DraggableCard.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 31 October 2025.
//  Last changed on 25 January 2026.
//

import SwiftUI
import DeadEndsLib

/// Handle dragging cards on the desktop.
struct DraggableCard<Content: View>: View {

    @Bindable var model: DesktopModel
    private let cardID: UUID
    private let content: Content
    private var card: Card? { model.cards.first(where: { $0.id == cardID }) }

    /// Create a draggable card.
    init(model: DesktopModel, cardID: UUID, @ViewBuilder content: () -> Content) {
        self.model = model
        self.cardID = cardID
        self.content = content()
    }

    // Draggable card view.
    var body: some View {
        Group {
            if let card = self.card {
                content
                    .position(currentPosition)
                    .gesture(dragGesture(for: card))
            } else {
                EmptyView()
            }
        }
    }

    /// Current card position.
    private var currentPosition: CGPoint {
        guard let card = card else { return .zero }
        if model.draggingID != nil, let start = model.dragStartPositions[card.id] {
            return CGPoint(
                x: start.x + model.dragOffset.width,
                y: start.y + model.dragOffset.height
            )
        }
        return card.position  // Not dragging.
    }

    /// Drag gesture for draggable cards.
    private func dragGesture(for card: Card) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if model.draggingID == nil {
                    model.draggingID = card.id
                    model.dragOffset = .zero

                    let dragIDs: Set<UUID>
                    if model.selectedIDs.contains(card.id) && model.selectedIDs.count > 1 {
                        dragIDs = model.selectedIDs
                    } else {
                        dragIDs = [card.id]
                    }
                    /*
                     // ChatGPT says this is a better way to get the dictionary.
                     model.dragStartPositions = Dictionary(uniqueKeysWithValues:
                         dragIDs.compactMap { id in
                             model.card(withId: id).map { (id, $0.position) }
                         }
                     )
                     */
                    var starts: [UUID: CGPoint] = [:]
                    for id in dragIDs {
                        if let c = model.card(withId: id) {
                            starts[id] = c.position
                        }
                    }
                    model.dragStartPositions = starts
                    model.bringToFront(card.id)
                }
                model.dragOffset = value.translation
            }
            .onEnded { _ in
                for (id, start) in model.dragStartPositions {
                    let newPos = CGPoint(
                        x: start.x + model.dragOffset.width,
                        y: start.y + model.dragOffset.height
                    )
                    model.updatePosition(for: id, to: newPos)
                }
                model.draggingID = nil
                model.dragOffset = .zero
                model.dragStartPositions = [:]
            }
    }
}
