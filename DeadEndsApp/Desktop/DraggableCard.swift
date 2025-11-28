//
//  DraggableCard.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 31 October 2025.
//  Last changed on 23 November 2025.
//

import SwiftUI
import DeadEndsLib

/// DraggableCard handles dragging Cards on the Desktop.
struct DraggableCard<Content: View>: View {

    @Bindable var model: DesktopModel
    private let cardID: UUID
    private let content: Content

    @State private var dragStartPosition: CGPoint? = nil
    @State private var lastDragCancelledToken: Int = 0   // local watcher

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

        if model.activeId == cardID {
            return CGPoint(
                x: card.position.x + model.activeOffset.width,
                y: card.position.y + model.activeOffset.height
            )
        }
        return card.position
    }

    var body: some View {
        guard let card else { return AnyView(EmptyView()) }

        return AnyView(
            content
                .position(currentPosition)
                .onChange(of: model.dragCancelledToken) { _, newValue in
                    // Snap or external cancel: kill the drag
                    lastDragCancelledToken = newValue
                    dragStartPosition = nil
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            //guard let card = card else { return }

                            // If a snap cancelled our drag, ignore further changes
                            if dragStartPosition == nil && model.activeId == nil {
                                return
                            }

                            // If another card is the active drag, ignore this one
                            if model.activeId != nil && model.activeId != cardID {
                                return
                            }

                            // BEGIN DRAG
                            if model.activeId == nil {
                                dragStartPosition = card.position
                                model.activeId = cardID
                                model.baseSize = card.baseSize
                            }

                            // CONTINUE DRAG
                            model.activeOffset = value.translation
                            model.tick &+= 1
                        }

                        .onEnded { value in
                            // If the drag was cancelled (via snap), ignore this onEnded
                            guard let start = dragStartPosition else {
                                dragStartPosition = nil
                                model.activeId = nil
                                model.activeOffset = .zero
                                model.baseSize = nil
                                return
                            }

                            // Final destination
                            let newPosition = CGPoint(
                                x: start.x + value.translation.width,
                                y: start.y + value.translation.height
                            )

                            model.updatePosition(for: cardID, to: newPosition)

                            // Reset drag state
                            dragStartPosition = nil
                            model.activeOffset = .zero
                            model.activeId = nil
                            model.baseSize = nil
                        }
                )
        )
    }
}
