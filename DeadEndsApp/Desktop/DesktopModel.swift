//
//  DesktopModel.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 22 October 2025.
//  Last changed on 17 January 2026.
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


    /// Add a card unless an equivalent exists.
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

    /// Remove cards matching a given kind.
    func removeCard(kind: CardValue) {
        
        cards.removeAll { card in
            switch (card.kind, kind) {

            case let (.person(p1), .person(p2)):
                return p1.key == p2.key

            case let (.family(f1), .family(f2)):
                return f1.key == f2.key

            // Match string cards *by UUID*, not by value.
            case let (.string(id1, _), .string(id2, _)):
                return id1 == id2

            default:
                return false
            }
        }
    }

    func bringToFront(_ id: UUID) {
        guard let i = cards.firstIndex(where: { $0.id == id }) else { return }
        let card = cards.remove(at: i)
        cards.append(card)
    }

    /// Find a card by ID.
    func card(withId id: UUID) -> Card? {
        cards.first { $0.id == id }
    }

    /// Find index of a card by ID.
    func indexOfCard(withId id: UUID) -> Int? {
        cards.firstIndex { $0.id == id }
    }

    /// Update size of a card.
    func updateSize(for id: UUID, to newSize: CGSize) {
        guard let index = cards.firstIndex(where: { $0.id == id }) else { return }
        cards[index].size = newSize
    }

    /// Update position of a card.
    func updatePosition(for id: UUID, to newPosition: CGPoint) {
        guard let index = cards.firstIndex(where: { $0.id == id }) else { return }
        cards[index].position = newPosition
    }

    /// Check if cards contains a person.
    nonisolated func contains(person: Person) -> Bool {
        MainActor.assumeIsolated {
            cards.contains {
                if case .person(let p) = $0.kind {
                    p.key == person.key
                } else { false }
            }
        }
    }

    /// Check if cards contains a family.
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
