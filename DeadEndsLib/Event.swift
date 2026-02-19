//
//  Event.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 27 June 2025.
//  Last changed on 17 February 2026.
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

//extension GedcomNode {
//
//    /// Return summary of an event. Assumes node is the parent of DATE and PLAC nodes.
//    public func eeventSummary(kind: EventKind) -> String? {
//        guard let event = self.eventOfKind(kind) else { return nil }
//        let date = year(from: event.dateVal)
//        let place = abbreviatedPlace(event.placeVal)
//
//        switch (date, place) {
//        case let (d?, p?): return "\(d), \(p)"
//        case let (d?, nil): return "\(d)"
//        case let (nil, p?): return p
//        default: return nil
//        }
//    }
//}

/// Event structure.
public struct Event: CustomStringConvertible {

    let node: GedcomNode   // Dad of DATE/PLAC nodes.
    let kind: EventKind
    public var dateNode: GedcomNode?  { node.kid(withTag: "DATE") }
    public var placeNode: GedcomNode? { node.kid(withTag: "PLAC") }
    public var dateVal: String?  { node.kidVal(forTag: "DATE") }
    public var placeVal: String? { node.kidVal(forTag: "PLAC") }

    /// Create event from node.
    public init?(node: GedcomNode, kind: EventKind) {
        guard kind.rawValue == node.tag else { return nil }
        self.node = node
        self.kind = kind
    }

    /// Create event from node figuring out event kine.
    public init?(node: GedcomNode) {
        self.node = node
        guard let kind = Event.eventKind(fromNode: node) else { return nil }
        self.kind = kind
    }

    /// Return description of event.
    public var description: String {
        "\(kind): \(dateVal.map(\.description) ?? "") \(placeVal.map(\.description) ?? "")"
    }

    public var year: Year? {
        DeadEndsLib.year(from: dateVal)
    }

    public var abbreviatedPlace: String? {
        DeadEndsLib.abbreviatedPlace(placeVal)
    }

    /// Return summary of event.
    public var summary: String? {

        //let date = DeadEndsLib.year(from: dateVal)
        let place = DeadEndsLib.abbreviatedPlace(placeVal)

        switch (year, place) {
        case let (d?, p?): return "\(d), \(p)"
        case let (d?, nil): return "\(d)"
        case let (nil, p?): return p
        default: return nil
        }
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

