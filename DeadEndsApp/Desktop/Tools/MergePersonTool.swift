//
//  MergePersonTool.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 3 November 2025.
//  Last changed on 19 November 2025.
//

import SwiftUI
import DeadEndsLib

/// Desktop Tool that merges two Persons.
struct MergePersonTool: View {

    @Bindable var model: DesktopModel

    @State private var slotAFrame: CGRect = .zero
    @State private var slotBFrame: CGRect = .zero
    @State private var dockedA: UUID? = nil
    @State private var dockedB: UUID? = nil

    private let magneticRadius: CGFloat = 150
    private let slotSize = CGSize(width: 160, height: 100)

    var canMerge: Bool { dockedA != nil && dockedB != nil }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .shadow(radius: 8)
                .frame(width: 420, height: 180)
                .overlay(toolContent)
        }
        .position(x: 500, y: 400)
        // Here is where the Tool becomes aware of Cards moving on the Desktop.
        .onChange(of: model.tick) { _, _ in
            updateMagneticBehavior()
        }
    }

    /// The content of the Tool, two Slots and the Merge command Button.
    private var toolContent: some View {
        VStack(spacing: 12) {

            Text("Merge Tool")
                .font(.headline)
                .padding(.top, 8)

            HStack(spacing: 16) {
                MergeSlotView(label: "Person A", rect: $slotAFrame)
                Image(systemName: "arrow.left.and.right")
                    .font(.title2)
                    .foregroundColor(.secondary)
                MergeSlotView(label: "Person B", rect: $slotBFrame)
            }

            Button(action: performMerge) {
                Label("Merge", systemImage: "arrow.triangle.merge")
            }
            .disabled(!canMerge)
        }
        .padding()
    }

    /// Performs the using the MergeWindowController.
    private func performMerge() {
        guard let idA = dockedA,
              let idB = dockedB,
              let cardA = model.card(withId: idA),
              let cardB = model.card(withId: idB),
              case .person(let left) = cardA.kind,
              case .person(let right) = cardB.kind
        else { return }

        MergeWindowController.open(left: left, right: right)
    }

    /// Updates the Merge Tool by tracking every tick in the Desktop's activities.
//    private func updateMagneticBehavior() {
//        // Find the active Card.
//        guard let activeId = model.activeId, let card = model.card(withId: activeId)
//        else { return }
//
//        // Get the current position of the active Card.
//        let livePosition = CGPoint(
//            x: card.position.x + model.activeOffset.width,
//            y: card.position.y + model.activeOffset.height
//        )
//
//        // Get the current rectangle of the active Card.
//        let size = card.displaySize
//        let cardRect = CGRect(
//            x: livePosition.x - size.width / 2,
//            y: livePosition.y - size.height / 2,
//            width: size.width,
//            height: size.height
//        )
//
//        // Get the centers of the active Card and the two Slots.
//        let cardCenter = CGPoint(x: cardRect.midX, y: cardRect.midY)
//        let centerA = CGPoint(x: slotAFrame.midX, y: slotAFrame.midY)
//        let centerB = CGPoint(x: slotBFrame.midX, y: slotBFrame.midY)
//
//        // Get the distances from the center of the active Card to the centers of the Slots.
//        let distA = hypot(cardCenter.x - centerA.x, cardCenter.y - centerA.y)
//        let distB = hypot(cardCenter.x - centerB.x, cardCenter.y - centerB.y)
//
//        let pA = max(0, 1 - distA / magneticRadius)
//        let pB = max(0, 1 - distB / magneticRadius)
//
//        // Scale toward closest slot
//        if pA > pB && pA > 0.05 {
//            let newSize = lerpSize(from: card.baseSize, to: slotSize, amount: pA)
//            model.updateDisplaySize(for: activeId, to: newSize)
//        } else if pB > 0.05 {
//            let newSize = lerpSize(from: card.baseSize, to: slotSize, amount: pB)
//            model.updateDisplaySize(for: activeId, to: size)
//        } else {
//            model.updateDisplaySize(for: activeId, to: card.displaySize)
//        }
//
//        // Snap into slot
//        if distA < 25 {
//            snap(cardID: activeId, to: centerA)
//            dockedA = activeId
//            dockedB = (dockedB == activeId) ? nil : dockedB
//            return
//        }
//
//        if distB < 25 {
//            snap(cardID: activeId, to: centerB)
//            dockedB = activeId
//            dockedA = (dockedA == activeId) ? nil : dockedA
//            return
//        }
//
//        if dockedA == activeId && distA ≥ 25 { dockedA = nil }
//        if dockedB == activeId && distB ≥ 25 { dockedB = nil }
//    }

    private func updateMagneticBehavior() {
        // Find the active Card.
        guard let activeId = model.activeId,
              let card = model.card(withId: activeId)
        else { return }

        // Current live position while dragging.
        let livePosition = CGPoint(
            x: card.position.x + model.activeOffset.width,
            y: card.position.y + model.activeOffset.height
        )

        // Rectangle using the *current display size*.
        let disp = card.displaySize
        let cardRect = CGRect(
            x: livePosition.x - disp.width / 2,
            y: livePosition.y - disp.height / 2,
            width: disp.width,
            height: disp.height
        )

        // Centers
        let cardCenter = CGPoint(x: cardRect.midX, y: cardRect.midY)
        let centerA = CGPoint(x: slotAFrame.midX, y: slotAFrame.midY)
        let centerB = CGPoint(x: slotBFrame.midX, y: slotBFrame.midY)

        // Distances
        let distA = hypot(cardCenter.x - centerA.x, cardCenter.y - centerA.y)
        let distB = hypot(cardCenter.x - centerB.x, cardCenter.y - centerB.y)

        // Normalized proximity values
        let pA = max(0, 1 - distA / magneticRadius)
        let pB = max(0, 1 - distB / magneticRadius)

        //----------------------------------------
        // 1. MAGNETIC SCALING WHILE DRAGGING
        //----------------------------------------
        if pA > pB && pA > 0.05 {
            // Warp toward Slot A
            let newSize = lerpSize(from: card.baseSize, to: slotSize, amount: pA)
            model.updateDisplaySize(for: activeId, to: newSize)

        } else if pB > 0.05 {
            // Warp toward Slot B
            let newSize = lerpSize(from: card.baseSize, to: slotSize, amount: pB)
            model.updateDisplaySize(for: activeId, to: newSize)

        } else {
            //----------------------------------------
            // Far from magnets → return to base size
            //----------------------------------------
            model.updateDisplaySize(for: activeId, to: card.baseSize)
        }

        //----------------------------------------
        // 2. SNAPPING INTO SLOTS
        //----------------------------------------
        if distA < 25 {
            snap(cardID: activeId, to: centerA)
            dockedA = activeId
            dockedB = (dockedB == activeId) ? nil : dockedB
            return
        }

        if distB < 25 {
            snap(cardID: activeId, to: centerB)
            dockedB = activeId
            dockedA = (dockedA == activeId) ? nil : dockedA
            return
        }

        //----------------------------------------
        // 3. UNDOCK IF MOVED AWAY
        //----------------------------------------
        if dockedA == activeId && distA >= 25 { dockedA = nil }
        if dockedB == activeId && distB >= 25 { dockedB = nil }
    }

    private func lerpSize(from: CGSize, to: CGSize, amount t: CGFloat) -> CGSize {
        CGSize(
            width: from.width + (to.width - from.width) * t,
            height: from.height + (to.height - from.height) * t
        )
    }

//    private func snap(cardID: UUID, to center: CGPoint) {
//        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
//            model.updatePosition(for: cardID, to: center)
//            model.updateDisplaySize(for: cardID, to: slotSize)
//        }
//        model.cancelActiveDrag()
//    }

    private func snap(cardID: UUID, to center: CGPoint) {
        // 1. Cancel drag BEFORE animation
        model.cancelActiveDrag()

        // 2. Animate into slot
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            model.updatePosition(for: cardID, to: center)
            model.updateDisplaySize(for: cardID, to: slotSize)
        }
    }
}

/// Slot View.
private struct MergeSlotView: View {
    let label: String
    @Binding var rect: CGRect

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 2, dash: [6]))
            .frame(width: CardConstants.minSize.width,
                   height: CardConstants.minSize.height)
            .background(GeometryReader { geo in
                Color.clear
                    .onAppear {
                        DispatchQueue.main.async {
                            rect = geo.frame(in: .named("desktop"))
                        }
                    }
                    .onChange(of: geo.frame(in: .named("desktop"))) { _, newFrame in
                        rect = newFrame
                    }
            })
            .overlay(Text(label).foregroundColor(.secondary))
    }
}
