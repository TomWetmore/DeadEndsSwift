//
//  DesktopModel.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 22 October 2025.
//  Last changed on 23 November 2025.
//

import Foundation
import DeadEndsLib

/// The view model that manages Card positions.
@MainActor
@Observable
class DesktopModel {

    var cards: [Card] = []  // Cards on the Desktop.
    var activeId: UUID? = nil  // Id of the card being dragged.
    var activeOffset: CGSize = .zero  // Offset of the card being dragged.
    var tools: [ToolModel] = []  // Tools on the Desktop.
    var tick: Int = 0  //  Tick count.
    var baseSize: CGSize? = nil   // Original size of Card being dragged.
    var dragCancelledToken = 0

    /// Adds a Card to the DesktopModel which will render it to the DesktopView.
    func addCard(kind: CardKind, position: CGPoint, size: CGSize) {
        switch kind {
        case .person(let person):
            guard !contains(person: person) else { return }
        case .family(let family):
            guard !contains(family: family) else { return }
        default:
            break // Allow for kinds that don’t need uniqueness.
        }
        cards.append(Card(kind: kind, position: position, size: size))
    }

    /// Removes all cards of the same kind (Person, Family or other) from the model.
    func removeCard(kind: CardKind) {
        cards.removeAll { card in
            switch (card.kind, kind) {
            case let (.person(p1), .person(p2)): // Person
                return p1.key == p2.key
            case let (.family(f1), .family(f2)): // Family
                return f1.key == f2.key
            case let (.string(p1), .string(p2)):  // String
                return p1 == p2
            default:
                return false
            }
        }
    }

    func card(withId id: UUID) -> Card? {
        cards.first(where: { $0.id == id })
    }

    func indexOfCard(withId id: UUID) -> Int? {
        cards.firstIndex(where: { $0.id == id })
    }

    func updateBaseSize(for id: UUID, to newSize: CGSize) {
        print("updateBaseSize called for card.id = \(id) ")
        if let index = cards.firstIndex(where: { $0.id == id }) {
            print("  delta from \(cards[index].baseSize) to \(newSize)")
            cards[index].baseSize = newSize
            tick &+= 1
            print("  confirming new size: \(cards[index].baseSize)")
        } else {
            print("  ERROR: card not found in DesktopModel.cards")
        }
    }

    func updateDisplaySize(for id: UUID, to newSize: CGSize) {
        print("updateDisplaySize called for card.id = \(id) ")
        if let index = cards.firstIndex(where: { $0.id == id }) {
            print("  delta from \(cards[index].displaySize) to \(newSize)")
            cards[index].displaySize = newSize
            tick &+= 1
            print("  confirming new size: \(cards[index].displaySize)")
        } else {
            print("  ERROR: card not found in DesktopModel.cards")
        }
    }

    /// Updates the position of a Card.
    func updatePosition(for id: UUID, to newPosition: CGPoint) {
        print("updatePosition called for card.id = \(id)")
        if let index = cards.firstIndex(where: { $0.id == id }) {
            print("  moved from \(cards[index].position) to \(newPosition)")
            cards[index].position = newPosition
            tick &+= 1
        }
    }

    nonisolated func contains(person: Person) -> Bool {
        MainActor.assumeIsolated {
            cards.contains {
                if case .person(let p) = $0.kind {
                    p.key == person.key
                } else {
                    false
                }
            }
        }
    }

    nonisolated func contains(family: Family) -> Bool {
        MainActor.assumeIsolated {
            cards.contains {
                if case .family(let p) = $0.kind {
                    p.key == family.key
                } else {
                    false
                }
            }
        }
    }

//    func cancelActiveDrag() {
//        activeOffset = .zero
//        activeId = nil
//    }

//    func cancelActiveDrag() {
//        activeId = nil
//        activeOffset = .zero
//        baseSize = nil
//        dragCancelled.toggle()    // <-- new Boolean
//    }

    func cancelActiveDrag() {
        activeId = nil
        activeOffset = .zero
        baseSize = nil
        dragCancelledToken &+= 1   // increment every time we cancel
    }
}

extension DesktopModel {

    func addTool(kind: ToolKind) {
        tools.append(ToolModel(kind: kind))
    }

    func removeTool(_ tool: ToolModel) {
        tools.removeAll { $0.id == tool.id }
    }

    func testMergeTool(personA: Person, personB: Person) {
        addTool(kind: .mergePersons(personA: personA, personB: personB))
    }
}
