//
//  ResizeableCard.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 31 October 2025.
//  Last changed on 22 November 2025.
//

import SwiftUI

struct ResizeableCard<Content: View>: View {

    @Bindable var model: DesktopModel
    let cardID: UUID
    let content: Content

    init(model: DesktopModel, cardID: UUID, @ViewBuilder content: () -> Content) {
        self.model = model
        self.cardID = cardID
        self.content = content()
    }

    /// Lookup card each render pass.
    private var card: Card? { model.cards.first(where: { $0.id == cardID }) }

    var body: some View {
        guard let card else { return AnyView(EmptyView()) }

        return AnyView(
            ZStack(alignment: .bottomTrailing) {
                content
                    .frame(width: card.displaySize.width, height: card.displaySize.height)
                    .clipped()
                resizeHandle
            }
        )
    }

    /// Lower-right resize handle.
    private var resizeHandle: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 10))
            .padding(6)
            .background(Color.white.opacity(0.7))
            .clipShape(Circle())
            .contentShape(Rectangle())  // hit test only here
            .gesture(dragGesture)  // .highPriorityGesture?
    }


    /// Smart resize gesture using DesktopModel
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard let card else { return }

                // Cancel active drag so resizing wins
                model.activeId = cardID
                model.activeOffset = .zero

                let old = card.baseSize

                // Proposed size
                var newWidth = old.width + value.translation.width
                var newHeight = old.height + value.translation.height

                // Clamp
                newWidth = min(max(newWidth, CardConstants.minSize.width),
                               CardConstants.maxSize.width)
                newHeight = min(max(newHeight, CardConstants.minSize.height),
                                CardConstants.maxSize.height)

                let newSize = CGSize(width: newWidth, height: newHeight)

                // Keep top-left corner fixed
                let dx = newWidth - old.width
                let dy = newHeight - old.height

                let newPosition = CGPoint(
                    x: card.position.x + dx / 2,
                    y: card.position.y + dy / 2
                )

                model.updateBaseSize(for: cardID, to: newSize)
                model.updateDisplaySize(for: cardID, to: newSize)
                model.updatePosition(for: cardID, to: newPosition)
            }
            .onEnded { _ in
                model.activeId = nil
                model.activeOffset = .zero
            }
    }
}
