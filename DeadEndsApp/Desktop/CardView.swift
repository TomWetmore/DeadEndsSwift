//
//  CardView.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 31 October 2025.
//  Last changed on 19 January 2026..
//

import SwiftUI
import DeadEndsLib

/// View that renders a card on the desktop.
struct CardView: View {

    @Bindable var model: DesktopModel
    let cardID: UUID
    @Environment(\.recordIndex) private var index: RecordIndex

    private var card: Card? {
        model.cards.first(where: { $0.id == cardID })
    }

    private var isSelected: Bool {
        model.selectedIDs.contains(cardID)
    }

    private let step = 1.13

	/// View to render a card on the desktop.
    var body: some View {
        
        if let card {
            ZStack(alignment: .topLeading) {

                RoundedRectangle(cornerRadius: 8)  // Blank index card.
                    .fill(Color(red: 1.0, green: 0.98, blue: 0.9))
                    .shadow(radius: 8)
                    .overlay(indexCardLines)

                VStack(alignment: .leading, spacing: 6) {

                    controls // Red, yellow, green control buttons.

                    switch card.kind {  // Person, family, string.
                    case let .string(_, value):
                        Text(value)
                    case .person(let person):
                        PersonCard(model: model, person: person)
                    case .family:
                        Text("Family Card")  // Replace with family card.
                            .font(.headline)
                    }
                    Spacer()
                }
                .padding(.bottom, 8)
                .padding(.leading, 6)
            }
            .frame(width: card.size.width, height: card.size.height)
            .overlay {  // Add selection ring to the card.
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentColor, lineWidth: 3)
                        .padding(-2)
                        .allowsHitTesting(false)
                }
            }
            .contextMenu { contextMenu(for: card) }
        } else {
            EmptyView()  // Disappeared or removed.
        }
    }

    /// Red, yellow, and green buttons in the upper left corner.
    private var controls: some View {
        
        HStack(spacing: 4) {
            Button(action: deleteCard) {  // Delete button.
                Circle().fill(Color.red).frame(width: 12, height: 10)
            }
            Button(action: shrinkCard) {  // Shrink button.
                Circle().fill(Color.yellow).frame(width: 12, height: 10)
            }
            Button(action: enlargeCard) {  // Enlarge button.
                Circle().fill(Color.green).frame(width: 12, height: 10)
            }
            Spacer()
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.top, 4)
        .padding(.leading, 4)
    }

    /// Delete card from the desktop.
    private func deleteCard() {
        guard let card else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            model.removeCard(kind: card.kind)
        }
    }

    /// Enlarge card one step.
    private func enlargeCard() {
        applyScale(step)
    }

    /// Shrink card one step.
    private func shrinkCard()  {
        applyScale(1 / step)
    }

    /// Change card size by factor.
    private func applyScale(_ factor: CGFloat) {
        
        guard let card else { return }
        let old = card.size
        var new = CGSize(width: old.width * factor, height: old.height * factor)
        new.width = min(max(new.width, CardSizes.minSize.width),
                        CardSizes.maxSize.width)
        new.height = min(max(new.height, CardSizes.minSize.height),
                         CardSizes.maxSize.height)
        let dx = new.width - old.width
        let dy = new.height - old.height
        let newPosition = CGPoint(x: card.position.x + dx / 2,
                                  y: card.position.y + dy / 2)
        withAnimation(.easeOut(duration: 0.15)) {
            model.updateSize(for: cardID, to: new)
            model.updatePosition(for: cardID, to: newPosition)
        }
    }

    /// Context menu for card based on its kind.
    private func contextMenu(for card: Card) -> some View {
        switch card.kind {
        case .person(let person):
            return AnyView(PersonContextMenu(person: person, index: index, model: model))
        case .family(let family):
            return AnyView(familyContextMenu(family))
        case .string:
            return AnyView(Text("Hello"))
        }
    }

	/// Adds index card lines to the Card's view.
    private var indexCardLines: some View {
        
        GeometryReader { geo in
            Path { path in
                let lineSpacing: CGFloat = 14
                var y = lineSpacing * 2
                while y < geo.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    y += lineSpacing
                }
            }
            .stroke(Color(red: 0.8, green: 0.9, blue: 1.0), lineWidth: 0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
