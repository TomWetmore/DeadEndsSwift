//
//  Event.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 27 June 2025.
//  Last changed on 4 October 2025
//

import Foundation


// GedcomNode extension dealing with events. self should be the root of a Gedcom record.
 public extension GedcomNode {

     // For an event node (like BIRT or MARR), return the first DATE subnode
     func dateNode() -> GedcomNode? {
         return self.kid(withTag: "DATE")
     }

     // For an event node (like BIRT or MARR), return the first PLAC subnode
     func placeNode() -> GedcomNode? {
         return self.kid(withTag: "PLAC")
     }

     // For an event node, return the value of the first DATE subnode, if any
     func dateValue() -> String? {
         return self.dateNode()?.val
     }

     // For an event node, return the value of the first PLAC subnode, if any
     func placeValue() -> String? {
         return self.placeNode()?.val
     }
 }

public extension GedcomNode {

    var date: String? {
        self.kidVal(forTag: "DATE")
    }

    var place: String? {
        self.kidVal(forTag: "PLAC")
    }
}

extension GedcomNode {

    /// Returns the summary for an event.
    public func eventSummary(tag: String) -> String? {
        guard let event = self.event(withTag: tag) else { return nil }
        let date = year(from: event.dateValue())
        let place = abbreviatedPlace(event.placeValue())

        switch (date, place) {
        case let (d?, p?): return "\(d), \(p)"
        case let (d?, nil): return d
        case let (nil, p?): return p
        default: return nil
        }
    }

    /// Returns the first child event node with the given tag (e.g., "BIRT"),
    /// A convience method because kid(withTag: tag) does the same thing.
    func event(withTag tag: String) -> GedcomNode? {
        kid(withTag: tag)
    }
}



