//
//  CardView.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 31 October 2025.
//  Last changed on 23 November 2025.
//

import SwiftUI
import DeadEndsLib

struct CardView: View {

    @Bindable var model: DesktopModel
    let cardID: UUID
    @Environment(\.recordIndex) private var index: RecordIndex

    private var card: Card? {
        model.cards.first(where: { $0.id == cardID })
    }

    private let step = 1.13

//    var body: some View {
//        guard let card else { return AnyView(EmptyView()) }
//
//        return AnyView(
//            ZStack(alignment: .topLeading) {
//
//                RoundedRectangle(cornerRadius: 8)
//                    .fill(Color(red: 1.0, green: 0.98, blue: 0.9))
//                    .shadow(radius: 8)
//                    .overlay(indexCardLines)
//
//                VStack(alignment: .leading, spacing: 6) {
//
//                    controls
//
//                    switch card.kind {
//                    case .string(let text):
//                        Text(text)
//                    case .person(let person):
//                        PersonCard(model: model, person: person)
//                    case .family:
//                        Text("Family Card")
//                            .font(.headline)
//                    }
//                    Spacer()
//                }
//                .padding(.bottom, 8)
//                .padding(.leading, 6)
//            }
//                .frame(width: card.displaySize.width,
//                       height: card.displaySize.height)
//                .contextMenu { contextMenu(for: card) }
//        )
//    }

    var body: some View {
        if let card {
            ZStack(alignment: .topLeading) {

                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 1.0, green: 0.98, blue: 0.9))
                    .shadow(radius: 8)
                    .overlay(indexCardLines)

                VStack(alignment: .leading, spacing: 6) {

                    controls

                    switch card.kind {
                    case let .string(_, value):
                        Text(value)
                    case .person(let person):
                        PersonCard(model: model, person: person)
                    case .family:
                        Text("Family Card")
                            .font(.headline)
                    }
                    Spacer()
                }
                .padding(.bottom, 8)
                .padding(.leading, 6)
            }
            .frame(width: card.displaySize.width,
                   height: card.displaySize.height)
            .contextMenu { contextMenu(for: card) }
        } else {
            // The card disappeared or was removed.
            EmptyView()
        }
    }

    /// The three controls in the upper left corner of the Card.
    private var controls: some View {
        HStack(spacing: 4) {
            Button(action: deleteCard) {
                Circle().fill(Color.red).frame(width: 12, height: 10)
            }
            Button(action: shrinkCard) {
                Circle().fill(Color.yellow).frame(width: 12, height: 10)
            }
            Button(action: enlargeCard) {
                Circle().fill(Color.green).frame(width: 12, height: 10)
            }
            Spacer()
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.top, 4)
        .padding(.leading, 4)
    }

    /// Delete the Card from the Desktop.
    private func deleteCard() {
        guard let card else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            model.removeCard(kind: card.kind)
        }
    }

    /// Enlarge the Card by one step factor.
    private func enlargeCard() { applyScale(step) }

    /// Shrink the Card by one step factor.
    private func shrinkCard()  { applyScale(1 / step) }

    /// Change the size of the Card by some factor.
    private func applyScale(_ factor: CGFloat) {
        guard let card else { return }

        let old = card.baseSize      // <-- use baseSize now
        var new = CGSize(width: old.width * factor, height: old.height * factor)

        new.width = min(max(new.width, CardConstants.minSize.width),
                        CardConstants.maxSize.width)
        new.height = min(max(new.height, CardConstants.minSize.height),
                         CardConstants.maxSize.height)

        let dx = new.width - old.width
        let dy = new.height - old.height
        let newPosition = CGPoint(x: card.position.x + dx / 2,
                                  y: card.position.y + dy / 2)

        withAnimation(.easeOut(duration: 0.15)) {
            model.updateBaseSize(for: cardID, to: new)
            model.updateDisplaySize(for: cardID, to: new)   // immediate sync
            model.updatePosition(for: cardID, to: newPosition)
        }
    }

    /// Context Menu for a Card based on its CardKind.
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
