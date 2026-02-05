//
//  Record.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 15 September 2025.
//  Last changed on 4 February 2026.
//

import Foundation

/// Would it be useful to have a RecordKind enum?
enum RecordKind: String {
    case header = "HEAD"
    case trailer = "TRLR"
    case person = "INDI"
    case family = "FAM"
    case source = "SOUR"
    case other =  "OTHR"
}

/// Record protocol; allows person, family, etc, to be types.
public protocol Record {
    var root: GedcomNode { get }  // Root of Record.
    var key: String { get }  // Key of Record.
}

/// Basic properties that forward to the record root.
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

/// Dictionary extension for record retrieval from indexes.
extension Dictionary where Key == String, Value == GedcomNode {
    public func person(for key: String) -> Person? { self[key].flatMap(Person.init) }
    public func family(for key: String) -> Family? { self[key].flatMap(Family.init) }
}

/// Foward useful methods to the Gedcom node level.
public extension Record {

    func gedcomText(level: Int = 0, indent: Bool = false) -> String { root.gedcomText(level: level, indent: indent) }
    //func oldEventSummary(tag: String) -> String? { root.eventSummary(tag: tag) }
    func eventSummary(kind: EventKind) -> String? { root.eventSummary(kind: kind) }
    func descendants() -> [GedcomNode] { root.descendants() }
    func count() -> Int { root.count() }
}

//func parseSingle<T>(text: String, wrap: (GedcomNode) -> T?) -> Result<T, [String]> {
//    let source = StringGedcomSource(name: "edit view", content: text)
//    var errlog = ErrorLog()
//    var tagmap = model.database!.tagmap
//
//    guard let nodes = loadRecords(from: source, tagMap: &tagmap, errlog: &errlog) else {
//        return .failure(["Parse failed (no records returned)"])
//    }
//    guard errlog.count == 0 else { return .failure(["Parse failed (syntax/validation errors)"]) }
//    guard nodes.count == 1 else { return .failure(["Expected exactly one record, found \(nodes.count)"]) }
//    guard let wrapped = wrap(nodes[0]) else { return .failure(["Record was not the expected type"]) }
//    return .success(wrapped)
//}

public extension Record {

    /// First event of this kind, in GEDCOM order.
    func eventOfKind(_ kind: EventKind) -> Event? {
        root.eventOfKind(kind)
    }

    /// All events of this kind, in GEDCOM order.
    func eventsOfKind(_ kind: EventKind) -> [Event] {
        root.eventsOfKind(kind)
    }
}

