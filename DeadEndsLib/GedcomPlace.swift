//
//  GedcomPlace.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 29 June 2025.
//  Last changed on 29 June 2025.
//

import Foundation

// MARK: - Place Simplification

/// Returns a simplified version of a GEDCOM place string,
/// keeping only the last `components` meaningful parts,
/// while optionally removing known suffixes like "United States" or "Canada".
func abbreviatedPlace(_ raw: String?, keeping components: Int = 2) -> String? {
    guard let raw = raw else { return nil }

    let noiseSuffixes = ["United States", "Canada"]

    // Split and trim each part
    var parts = raw
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

    // Drop noisy suffix if present and enough components remain
    if let last = parts.last,
       noiseSuffixes.contains(last),
       parts.count > 2 {
        parts.removeLast()
    }

    return parts.suffix(components).joined(separator: ", ")
}
