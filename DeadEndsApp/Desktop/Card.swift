//
//  Card.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 22 October 2025.
//  Last changed on 26 January 2026.
//

import SwiftUI
import DeadEndsLib

/// Card value of card that appears on the desktop.
enum CardValue {
    case person(Person)
    case family(Family)
    case string(id: UUID, value: String)
}

/// Size constants.
struct CardSizes {
    static let minSize  = CGSize(width: 171.0, height: 107.0)
    static let startSize = CGSize(width: 240.0, height: 150.0)
    static let maxSize  = CGSize(width: 934.0, height: 584.0)
}

/// Struct holding a card value, position and size.
struct Card: Identifiable, Equatable, Hashable {

    let id = UUID()
    let kind: CardValue  // Person, family, ... ('value' of Card).
    var position: CGPoint  // Center coords in 'desktop' system.
    var size: CGSize  // Card's size.

    var rect: CGRect {  // Card's rectangle (computed property).
        CGRect(x: position.x - size.width / 2, y: position.y - size.height / 2,
               width: size.width, height: size.height)
    }
    var topCenter: CGPoint { CGPoint(x: rect.midX, y: rect.minY) }
    var bottomCenter: CGPoint { CGPoint(x: rect.midX, y: rect.maxY) }
    var leftCenter: CGPoint { CGPoint(x: rect.minX, y: rect.midY) }
    var rightCenter: CGPoint { CGPoint(x: rect.maxX, y: rect.midY) }

    /// Create a new card.
    init(kind: CardValue, position: CGPoint, size: CGSize) {
        self.kind = kind
        self.position = position
        self.size = size
    }

    /// Compare two cards for Equatable.
    static func == (lhs: Card, rhs: Card) -> Bool {
        lhs.id == rhs.id
    }

    /// Hash card to Hashable.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
