//
//  Record.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 15 September 2025.
//  Last changed on 18 February 2026.
//

import Foundation

/// Kinds of records.
enum RecordKind: String {
    case header = "HEAD"
    case trailer = "TRLR"
    case person = "INDI"
    case family = "FAM"
    case source = "SOUR"
    case other =  "OTHR"
}

/// Record protocol; allow person, family, etc, to be types.
public protocol Record {
    var root: GedcomNode { get }  // Record root.
    var key: String { get }  // Record key.
}

/// Properties forwarded to the record root.
public extension Record {

    // Base properties.
    var key: String { root.key! }
    var tag: String { root.tag }
    var val: String? { root.val }
    var kid: GedcomNode? { root.kid }
    var sib: GedcomNode? { root.sib }

    // Retrieval methods.
    func kid(withTag tag: String) -> GedcomNode? { root.kid(withTag: tag) }
    func kid(atPath path: [String]) -> GedcomNode? { root.kid(atPath: path) }

    func kidVal(forTag tag: String) -> String? { root.kidVal(forTag: tag) }
    func kidVal(atPath path: [String]) -> String? { root.kidVal(atPath: path) }

    func kids(withTag tag: String) -> [GedcomNode] { root.kids(withTag: tag) }
    func kidVals(forTag tag: String) -> [String] { root.kidVals(forTag: tag) }
    func kidVals(forTags tags: [String]) -> [String] {root.kidVals(forTags: tags) }
}

/// Extension for record retrieval from indexes.
extension Dictionary where Key == String, Value == GedcomNode {

    /// Create person from root.
    public func person(for key: String) -> Person? { self[key].flatMap(Person.init) }

    /// Create family from root.
    public func family(for key: String) -> Family? { self[key].flatMap(Family.init) }
}

/// Foward useful methods to the Gedcom node level.
public extension Record {

    func gedcomText(level: Int = 0, indent: Bool = false) -> String { root.gedcomText(level: level, indent: indent) }
    func descendants() -> [GedcomNode] { root.descendants() }
    func count() -> Int { root.count() }
}

public extension Record {

    /// First event of this kind in Gedcom order.
    func eventOfKind(_ kind: EventKind) -> Event? {
        root.eventOfKind(kind)
    }

    /// All events of this kind in Gedcom order.
    func eventsOfKind(_ kind: EventKind) -> [Event] {
        root.eventsOfKind(kind)
    }
}

