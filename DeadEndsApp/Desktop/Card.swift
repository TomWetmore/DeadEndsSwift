//
//  Card.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 22 October 2025.
//  Last changed on 26 November 2025.
//

import SwiftUI
import DeadEndsLib

/// Kinds of Cards that can appear on the Desktop.
enum CardKind: Identifiable, Hashable {
    case person(Person)
    case family(Family)
    case string(id: UUID, value: String)

    var id: String {
        switch self {
        case .person(let person): return person.root.key!
        case .family(let family): return family.root.key!
        case .string(let id, _):  return id.uuidString
        }
    }
}

/// Constants for use with Cards; aspect ration of 1.6 and growth rate of 1.15.
struct CardConstants {
    static let minSize = CGSize(width: 171.0, height: 107.0)
    static let startSize = CGSize(width: 240.0, height: 150.0)
    static let maxSize = CGSize(width: 934.0, height: 584.0)
}

/// A model for a draggable card on the canvas.
struct Card: Identifiable, Equatable, Hashable {
    let id = UUID()
    let kind: CardKind
    var position: CGPoint
    var baseSize: CGSize  // User specified size.
    var displaySize: CGSize  // Display size (eg. magnetic effects).

    init(kind: CardKind, position: CGPoint, size: CGSize) {
        self.kind = kind
        self.position = position
        self.baseSize = size
        self.displaySize = size
    }

    static func == (lhs: Card, rhs: Card) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
