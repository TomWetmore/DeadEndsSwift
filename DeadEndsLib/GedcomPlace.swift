//
//  GedcomPlace.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 29 June 2025.
//  Last changed on 19 September 2025.
//

import Foundation

/// Returns an abbreviated version of a Gedcom place string,
func abbreviatedPlace(_ value: String?, keeping keep: Int = 2) -> String? {

    guard let value = value else { return nil }
    let noiseSuffixes = ["United States", "Canada", "USA", "US", "United Kingdom"]
    var parts = value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

    if let last = parts.last, noiseSuffixes.contains(last), parts.count > keep { parts.removeLast() }

    if keep == 2 && parts.count >= 3 { return "\(parts.first!), \(parts.last!)" }
    return parts.suffix(keep).joined(separator: ", ")
}
