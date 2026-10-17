//
//  Record.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 15 September 2025.
//  Last changed on 16 October 2026.
//

import Foundation

/// Kinds of records.
///
enum RecordKind: String {

    case header = "HEAD"
    case trailer = "TRLR"
    case person = "INDI"
    case family = "FAM"
    case source = "SOUR"
    case other =  "OTHR"
}

/// Protocol that allows Person, Family, Source, etc, to be types.
///
public protocol Record {

    var root: Root { get }  // Record root.
    var key: String { get }  // Record key.

    init(_ root: Root)
}

public extension Record {
    
    func deepCopy() -> Self {
        Self(root.deepCopy())
    }
}

/// GedcomNode properties that are forwarded to the root GedcomNode.
///
public extension Record {

    var key: String { root.key! }

    var tag: String { root.tag }

    var val: String? { root.val }

    var kid: GedcomNode? { root.kid }

    var sib: GedcomNode? { root.sib }

    var subnodes: [GedcomNode] { root.subnodes }

    var count: Int { root.count }
}

/// GedcomNode methods that are forwarded to the root GedcomNode.
///
public extension Record {

    func kid(withTag tag: Tag) -> GedcomNode? {

        root.kid(withTag: tag)
    }

    func kid(atPath path: [Tag]) -> GedcomNode? {

        root.kid(atPath: path)
    }

    func kidVal(forTag tag: Tag) -> String? {

        root.kidVal(forTag: tag)
    }

    func kidVal(atPath path: [Tag]) -> String? {

        root.kidVal(atPath: path)
    }

    func kids(withTag tag: Tag) -> [GedcomNode] {

        root.kids(withTag: tag)
    }

    func kids(withTags tags: [Tag]) -> [GedcomNode] {

        root.kids(withTags: tags)
    }

    func kidVals(forTag tag: Tag) -> [String] {

        root.kidVals(forTag: tag)
    }

    func kidVals(forTags tags: [Tag]) -> [String] {

        root.kidVals(forTags: tags)
    }

    func gedcomText(indent: String = "") -> String {

        root.gedcomText(indent: indent)
    }
}

public extension Record {

    /// Find first event of this kind in Gedcom order.
    ///
    func eventOfKind(_ kind: EventKind) -> Event? {

        root.eventOfKind(kind)
    }

    /// Find all events of this kind in Gedcom order.
    ///
    func eventsOfKind(_ kind: EventKind) -> [Event] {
        
        root.eventsOfKind(kind)
    }
}

