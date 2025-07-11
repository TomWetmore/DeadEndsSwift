//
//  Event.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 27 June 2025.
//  Last changed on 27 June 2025
//

import Foundation

/*

1. Getting an event -- returns the GedcomNode that roots the event.
2. Getting the date of an event -- could want eitehr the DATE GedcomNode or its value.
3. Getting the place of an event -- could want either the PLAC GedcomNode or its value.
4. Getting a single string to summarie the event, the values of the first DATE and PLAC
   GedcomNodes somehow merged.

 */


// GedcomNode extension dealing with events. self should be the root of a Gedcom record.
 public extension GedcomNode {

     // event(withTag:) returns the first child event node with the given tag (e.g., "BIRT")
     func event(withTag tag: String) -> GedcomNode? {
         return self.child(withTag: tag)
     }

     // For an event node (like BIRT or MARR), return the first DATE subnode
     func dateNode() -> GedcomNode? {
         return self.child(withTag: "DATE")
     }

     // For an event node (like BIRT or MARR), return the first PLAC subnode
     func placeNode() -> GedcomNode? {
         return self.child(withTag: "PLAC")
     }

     // For an event node, return the value of the first DATE subnode, if any
     func dateValue() -> String? {
         return self.dateNode()?.value
     }

     // For an event node, return the value of the first PLAC subnode, if any
     func placeValue() -> String? {
         return self.placeNode()?.value
     }

     // For a person or family node, returns a summary of the specified event (e.g., "1870, Boston")
     func eventSummary(tag: String) -> String? {
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
 }


