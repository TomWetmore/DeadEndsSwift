//
//  Record.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 15 September 2025.
//  Last changed on 20 September 2025.
//

import Foundation

/// Defines a Protocol for Gedcom Records. Allows Person, Family, Source, et al, to be their own Swift types.
/// A Record holds a level 0 GedcomNode and its reference key.
public protocol Record {
    var root: GedcomNode { get }  // Root of Record.
    var key: String { get }  // Key of Record.
}

/// Extension with the basic properties and methods of GedcomNodes.
public extension Record {
    // Base properties.
    var key: String { root.key! }  // Meets protocol requirment.
    var tag: String { root.tag }
    var val: String? { root.val }
    var kid: GedcomNode? { root.kid }
    var sib: GedcomNode? { root.sib }

    // Retrieval methods.
    func kidVal(forTag tag: String) -> String? { root.kidVal(forTag: tag) }
    func kidVals(forTag tag: String) -> [String] { root.kidVals(forTag: tag) }
    func kid(withTag tag: String) -> GedcomNode? { root.kid(withTag: tag) }
    func kids(withTag tag: String) -> [GedcomNode] { root.kids(withTag: tag) }
}

/// Extensions to Dictionary that allows Record retrieval from RecordIndexes.
extension Dictionary where Key == String, Value == GedcomNode {
    public func person(for key: String) -> Person? { self[key].flatMap(Person.init) }
    public func family(for key: String) -> Family? { self[key].flatMap(Family.init) }
    //public func source(for key: String) -> Source? { self[key].flatMap(Source.init) } // Future.
}

/// Extensions that foward useful methods to the Record level.
public extension Record {
    func gedcomText(level: Int = 0, indent: Bool = false) -> String { root.gedcomText(level: level, indent: indent) }
    func eventSummary(tag: String) -> String? { root.eventSummary(tag: tag) }
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

