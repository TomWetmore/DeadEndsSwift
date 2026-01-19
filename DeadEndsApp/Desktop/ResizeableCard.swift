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
                    .frame(width: card.size.width, height: card.size.height)
                    //.clipped()
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
            .gesture(resizeGesture)
    }

    /// Card resize gesture.
    private var resizeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard let card else { return }

                if model.resizingId != cardID {  // Resizing in progress.
                    model.resizingId = cardID
                }

                let oldSize = card.size

                // Proposed size
                var newWidth = oldSize.width + value.translation.width
                var newHeight = oldSize.height + value.translation.height

                // Clamp
                newWidth = min(max(newWidth, CardSizes.minSize.width),
                               CardSizes.maxSize.width)
                newHeight = min(max(newHeight, CardSizes.minSize.height),
                                CardSizes.maxSize.height)

                let newSize = CGSize(width: newWidth, height: newHeight)

                // Keep top-left corner fixed
                let dx = newWidth - oldSize.width
                let dy = newHeight - oldSize.height

                let newPosition = CGPoint(
                    x: card.position.x + dx / 2,
                    y: card.position.y + dy / 2
                )

                model.updateSize(for: cardID, to: newSize)
                model.updatePosition(for: cardID, to: newPosition)
            }
            .onEnded { _ in
                if model.resizingId == cardID {
                                model.resizingId = nil
                            }
            }
    }
}
