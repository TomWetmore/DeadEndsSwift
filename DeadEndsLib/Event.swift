//
//  Event.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 27 June 2025.
//  Last changed on 16 February 2026.
//

import Foundation

/// May not need to have a raw value base on some current uses.
public enum EventKind: String {
    case birth = "BIRT"
    case death = "DEAT"
    case marriage = "MARR"
    case divorce = "DIV"
    case burial = "BUR"
}

// Helpers for nodes with DATE/PLAC kids, e.g., BIRT, DEAT, MARR.
/// NOTE: In most cases should now use the new Event API to get this information.
public extension GedcomNode {
    var dateNode: GedcomNode? { self.kid(withTag: "DATE") }
    var placeNode: GedcomNode? { self.kid(withTag: "PLAC") }
    var dateVal: String? { self.kidVal(forTag: "DATE") }
    var placeVal: String? { self.kidVal(forTag: "PLAC") }
}

extension GedcomNode {

    /// Returns the summary for an event. Assumes self is parent of DATE and PLAC nodes.
    public func eventSummary(kind: EventKind) -> String? {
        guard let event = self.eventOfKind(kind) else { return nil }
        let date = year(from: event.dateVal)
        let place = abbreviatedPlace(event.placeVal)

        switch (date, place) {
        case let (d?, p?): return "\(d), \(p)"
        case let (d?, nil): return d
        case let (nil, p?): return p
        default: return nil
        }
    }
}

/// Event structure.
public struct Event {
    let node: GedcomNode   // Parent of DATE/PLAC nodes.
    let kind: EventKind
    public var dateNode: GedcomNode?  { node.dateNode }
    public var placeNode: GedcomNode? { node.placeNode }
    public var dateVal: String?  { node.dateVal }
    public var placeVal: String? { node.placeVal }

    public init?(node: GedcomNode, kind: EventKind) {
        guard kind.rawValue == node.tag else { return nil }
        self.node = node
        self.kind = kind
    }

    public init?(node: GedcomNode) {
        self.node = node
        guard let kind = Event.eventKind(fromNode: node) else { return nil }
        self.kind = kind
    }

    /// Determine event kind from node.
    static func eventKind(fromNode node: GedcomNode) -> EventKind? {
        eventKind(fromTag: node.tag)
    }

    /// Determine event kind from tag.
    static func eventKind(fromTag tag: String) -> EventKind? {
        switch tag {
        case "BIRT": return .birth
        case "DEAT": return .death
        case "MARR": return .marriage
        case "DIV": return .divorce
        case "BUR": return .burial
        default: return nil
        }
    }
}

public extension GedcomNode {

    /// Create event from node; failable.
    var asEvent: Event? { Event(node: self) }

    /// Create single event of a kind from a (root) node.
    func eventOfKind(_ kind: EventKind) -> Event? {
        self.eventsOfKind(kind).first
    }

    /// Create events of a kind from a (root) node.
    func eventsOfKind(_ kind: EventKind) -> [Event] {
        self.kids(withTag: kind.rawValue).compactMap { Event(node: $0) }
    }
}

