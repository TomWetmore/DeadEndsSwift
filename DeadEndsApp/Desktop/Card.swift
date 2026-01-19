//
//  Card.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 22 October 2025.
//  Last changed on 16 January 2026.
//

import SwiftUI
import DeadEndsLib

/// Values of cards that appear on the desktop.
enum CardValue: Identifiable, Hashable {

    case person(Person)
    case family(Family)
    case string(id: UUID, value: String)

    /// Stable ID for each card value type.
    var id: String {
        switch self {
        case .person(let person):
            return person.root.key ?? UUID().uuidString
        case .family(let family):
            return family.root.key ?? UUID().uuidString
        case .string(let id, _):
            return id.uuidString
        }
    }
}

/// Card size constants.
struct CardSizes {
    static let minSize  = CGSize(width: 171.0, height: 107.0)
    static let startSize = CGSize(width: 240.0, height: 150.0)
    static let maxSize  = CGSize(width: 934.0, height: 584.0)
}

/// Struct holding a card value.
struct Card: Identifiable, Equatable, Hashable {

    let id = UUID()
    let kind: CardValue  // Person, family, ...
    var position: CGPoint  // Card center in desktop coordinates.
    var size: CGSize  // Card size.

    init(kind: CardValue, position: CGPoint, size: CGSize) {
        self.kind = kind
        self.position = position
        self.size = size
    }

    static func == (lhs: Card, rhs: Card) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
