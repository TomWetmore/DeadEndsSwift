//
//  DesktopModel.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 22 October 2025.
//  Last changed on 22 January 2026.
//

import Foundation
import DeadEndsLib

/// Model for the cards on a desktop.
@MainActor
@Observable
class DesktopModel {

    var cards: [Card] = []  // Cards on the desktop.
    var draggingID: UUID? = nil  // ID of card being dragged.
    var resizingId: UUID? = nil   // ID of card being resized.
    var dragOffset: CGSize = .zero
    var selectedIDs: Set<UUID> = []  // IDs of selected cards.

    /// Add card to model unless an equivalent exists.
    func addCard(kind: CardValue, position: CGPoint, size: CGSize) {
        switch kind {
        case .person(let person):
            guard !contains(person: person) else { return }
        case .family(let family):
            guard !contains(family: family) else { return }
        default:
            break
        }
        cards.append(Card(kind: kind, position: position, size: size))
    }

    /// Remove cards from model matching a given kind.
    func removeCard(kind: CardValue) {
        cards.removeAll { card in
            switch (card.kind, kind) {
            case let (.person(p1), .person(p2)):
                return p1.key == p2.key
            case let (.family(f1), .family(f2)):
                return f1.key == f2.key
            case let (.string(id1, _), .string(id2, _)):  // Match by UUID, not value.
                return id1 == id2
            default:
                return false
            }
        }
    }

    /// Move card to first position in array.
    func bringToFront(_ id: UUID) {
        guard let i = cards.firstIndex(where: { $0.id == id }) else { return }
        let card = cards.remove(at: i)
        cards.append(card)
    }

    /// Find card by ID.
    func card(withId id: UUID) -> Card? {
        cards.first { $0.id == id }
    }

    /// Find card index by ID.
    func indexOfCard(withId id: UUID) -> Int? {
        cards.firstIndex { $0.id == id }
    }

    /// Update card size.
    func updateSize(for id: UUID, to newSize: CGSize) {
        guard let index = cards.firstIndex(where: { $0.id == id }) else { return }
        cards[index].size = newSize
    }

    /// Update card position.
    func updatePosition(for id: UUID, to newPosition: CGPoint) {
        guard let index = cards.firstIndex(where: { $0.id == id }) else { return }
        cards[index].position = newPosition
    }

    /// Check if cards contains person.
    nonisolated func contains(person: Person) -> Bool {
        MainActor.assumeIsolated {
            cards.contains {
                if case .person(let p) = $0.kind {
                    p.key == person.key
                } else { false }
            }
        }
    }

    /// Check if cards contains family.
    nonisolated func contains(family: Family) -> Bool {
        MainActor.assumeIsolated {
            cards.contains {
                if case .family(let f) = $0.kind {
                    f.key == family.key
                } else { false }
            }
        }
    }
}

extension DesktopModel {

    /// Front-most selected card (top of z-order = last in `cards`).
    func primarySelectedCardID() -> UUID? {
        cards.last(where: { selectedIDs.contains($0.id) })?.id
    }

    func selectedCards() -> [Card] {
        cards.filter { selectedIDs.contains($0.id) }
    }
}

extension DesktopModel {

    func makeSelectedSameSize() {
        guard selectedIDs.count >= 2 else { return }
        guard let primaryID = primarySelectedCardID(),
              let primary = card(withId: primaryID) else { return }

        let target = primary.size

        for id in selectedIDs {
            guard let idx = indexOfCard(withId: id) else { continue }
            cards[idx].size = target
            // keep center position unchanged
        }
    }
}

extension DesktopModel {

    enum AlignEdge {
        case left, right, top, bottom
    }

    func alignSelected(_ edge: AlignEdge) {
        guard selectedIDs.count >= 2 else { return }

        // Compute the target edge value among selected cards.
        let selected = selectedCards()
        guard !selected.isEmpty else { return }

        func left(_ c: Card) -> CGFloat { c.position.x - c.size.width / 2 }
        func right(_ c: Card) -> CGFloat { c.position.x + c.size.width / 2 }
        func top(_ c: Card) -> CGFloat { c.position.y - c.size.height / 2 }
        func bottom(_ c: Card) -> CGFloat { c.position.y + c.size.height / 2 }

        let target: CGFloat
        switch edge {
        case .left:   target = selected.map(left).min() ?? 0
        case .right:  target = selected.map(right).max() ?? 0
        case .top:    target = selected.map(top).min() ?? 0
        case .bottom: target = selected.map(bottom).max() ?? 0
        }

        // Move each selected card so its chosen edge matches target.
        for id in selectedIDs {
            guard let idx = indexOfCard(withId: id) else { continue }
            let c = cards[idx]
            switch edge {
            case .left:
                cards[idx].position.x = target + c.size.width / 2
            case .right:
                cards[idx].position.x = target - c.size.width / 2
            case .top:
                cards[idx].position.y = target + c.size.height / 2
            case .bottom:
                cards[idx].position.y = target - c.size.height / 2
            }
        }
    }
}

extension DesktopModel {

    enum DistributeAxis { case horizontal, vertical }

    func distributeSelected(_ axis: DistributeAxis) {
        guard selectedIDs.count >= 3 else { return }

        // Gather indices of selected cards in sorted order along axis.
        var idxs: [Int] = []
        for (i, c) in cards.enumerated() where selectedIDs.contains(c.id) {
            idxs.append(i)
        }

        idxs.sort { a, b in
            switch axis {
            case .horizontal: return cards[a].position.x < cards[b].position.x
            case .vertical:   return cards[a].position.y < cards[b].position.y
            }
        }

        guard idxs.count >= 3 else { return }

        let first = cards[idxs.first!].position
        let last  = cards[idxs.last!].position

        let n = CGFloat(idxs.count - 1)

        switch axis {
        case .horizontal:
            let dx = (last.x - first.x) / n
            for (k, i) in idxs.enumerated() {
                cards[i].position.x = first.x + CGFloat(k) * dx
            }
        case .vertical:
            let dy = (last.y - first.y) / n
            for (k, i) in idxs.enumerated() {
                cards[i].position.y = first.y + CGFloat(k) * dy
            }
        }
    }
}
