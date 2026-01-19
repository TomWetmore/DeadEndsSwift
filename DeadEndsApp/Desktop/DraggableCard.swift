//
//  DraggableCard.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 31 October 2025.
//  Last changed on 16 January 2026.
//

import SwiftUI
import DeadEndsLib

/// DraggableCard handles dragging Cards on the Desktop.
struct DraggableCard<Content: View>: View {

    @Bindable var model: DesktopModel
    private let cardID: UUID
    private let content: Content

    @State private var dragStartPosition: CGPoint? = nil

    private var card: Card? {
        model.cards.first(where: { $0.id == cardID })
    }

    init(model: DesktopModel, cardID: UUID, @ViewBuilder content: () -> Content) {
        self.model = model
        self.cardID = cardID
        self.content = content()
    }

    private var currentPosition: CGPoint {
        guard let card else { return .zero }

        if model.draggingID == cardID {
            return CGPoint(
                x: card.position.x + model.dragOffset.width,
                y: card.position.y + model.dragOffset.height
            )
        }
        return card.position
    }

    var body: some View {
        guard let card else { return AnyView(EmptyView()) }

        return AnyView(
            content
                .position(currentPosition)
                .gesture(
                    DragGesture()
                        .onChanged { value in

                            // If another card is active, ignore
                            if model.draggingID != nil && model.draggingID != cardID {
                                return
                            }
                            if model.draggingID == nil { // Begin drag.
                                dragStartPosition = card.position
                                model.draggingID = cardID
                            }
                            model.dragOffset = value.translation // Continue drag.
                        }

                        .onEnded { value in
                            guard let start = dragStartPosition else {
                                // Drag was cancelled by snap
                                dragStartPosition = nil
                                model.draggingID = nil
                                model.dragOffset = .zero
                                //model.baseSize = nil
                                return
                            }

                            // Commit new position
                            let newPosition = CGPoint(
                                x: start.x + value.translation.width,
                                y: start.y + value.translation.height
                            )

                            model.updatePosition(for: cardID, to: newPosition)

                            dragStartPosition = nil // Reset.
                            model.dragOffset = .zero
                            model.draggingID = nil
                        }
                )
        )
    }
}
