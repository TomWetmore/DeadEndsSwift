//
//  PlaceIndex.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 22 November 2025.
//  Last changed on 25 November 2025.
//

import Foundation

typealias PlaceKey = String

/// Provides the PlaceIndex feature on a Database.
final public class PlaceIndex {

    private(set) var index: [PlaceKey : Set<RecordKey>] = [:]

    /// Adds entries to the PlaceIndex. The place argument is canonicalized into parts.
    func add(place: String, recordKey: RecordKey) {
        let parts = placeParts(place)
        guard !parts.isEmpty else { return }

        for part in parts {
            index[part, default: Set()].insert(recordKey)
        }
    }

    /// Removes entries from the PlaceIndex. The place argument is canonicalized into parts.
    func remove(place: String, recordKey: RecordKey) {
        let parts = placeParts(place)
        for part in parts {
            guard var keys = index[part] else { continue }
            keys.remove(recordKey)
            if keys.isEmpty { index.removeValue(forKey: part) }
            else { index[part] = keys }
        }
    }

    /// Gets the Set of RecordKeys for a Place component, aka PlaceKey.
    func keys(placeKey: PlaceKey) -> Set<RecordKey>? {
        return index[placeKey]
    }
}

/// Collects all PLAC values, at any level, and returns them as an Array of Strings.
func collectAllPlaceStrings(from recordIndex: RecordIndex) -> [String] {
    var results: [String] = []
    var records = 0

    for (_, root) in recordIndex {
        records += 1
        for node in root.descendants() {
            if node.tag == "PLAC", let value = node.val {
                results.append(value)
            }
        }
    }
    print("collected \(results.count) PLAC values across \(records) records")
    return results
}

/// Finds the canonical parts of a Gedcom PLAC value.
func placeParts(_ raw: String) -> [String] {

    var string = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

    let noiseWords = [ // Words and phrases to strip.
        "prob ", "probable ", "probably ",
        "poss ", "possible ", "possibly ",
        "near ", "about ", "abt ", "circa ",
        "city of ", "county of "
    ]
    for word in noiseWords {
        string = string.replacingOccurrences(of: word, with: " ")
    }

    while string.contains("  ") {  // Collapse duplicate spaces.
        string = string.replacingOccurrences(of: "  ", with: " ")
    }

    let commaParts = string  // Split into comma-separated components.
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) }

    var allParts: [String] = []
    for part in commaParts {  // Check for " or " separators.
        if part.contains(" or ") {
            let ors = part.split(separator: " or ").map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            allParts.append(contentsOf: ors)
        } else {
            allParts.append(part)
        }
    }

    let dropCountries: Set<String> = [  // Drop some country name parts.
        "united states", "united states of america", "usa",
        "u.s.", "u.s.a", "us", "canada"
    ]
    var cleaned: [String] = []

    for var part in allParts {  // Per component cleanup.
        if part.isEmpty { continue }
        if dropCountries.contains(part) { continue }

        if part.hasSuffix(" city") {  // Remove " city" and " county" suffixes.
            part = String(part.dropLast(" city".count))
        }
        if part.hasSuffix(" county") {
            part = String(part.dropLast(" county".count))
        }

        part = part.trimmingCharacters(in: .whitespaces)
        if !part.isEmpty {
            cleaned.append(part)
        }
    }

    return cleaned
}

/// Builds a PlaceIndex from a RecordList.
func buildPlaceIndex(from records: RecordList) -> PlaceIndex {
    let placeIndex = PlaceIndex()

    for root in records {
        guard let key = root.key else { continue }

        // Scan all descendants for PLAC line
        for node in root.descendants() {
            if node.tag == "PLAC", let value = node.val {
                placeIndex.add(place: value, recordKey: key)
            }
        }
    }
    return placeIndex
}

extension PlaceIndex {

    /// Debug method that prints the contents of a PlaceIndex.
    func showContents(using recordIndex: RecordIndex) {
           let sortedEntries = index.sorted { $0.key < $1.key }

           for (part, recordKeys) in sortedEntries {
               for key in recordKeys.sorted() {
                   if let person = recordIndex.person(for: key) {
                       print("\(part): \(person.displayName()) [\(key)]")
                   }
                   else if recordIndex.family(for: key) != nil {
                       print("\(part): Family \(key)")
                   }
                   else {
                       print("\(part): ??? (\(key))")
                   }
               }
           }
       }
}

// Move to more central location.
extension Dictionary where Value: Collection {

    func sortedByValueCount(descending: Bool = true) -> [(Key, Value)] {
        self.sorted {
            descending
                ? $0.value.count > $1.value.count
                : $0.value.count < $1.value.count
        }
    }
}

/// Debug function that shows the frequency table for a PlaceIndex.
func showPlaceFrequencyTable(_ index: PlaceIndex) {
    var total: Int = 0
    let sorted = index.index.sortedByValueCount()
    for (part, keys) in sorted {
        print("\(part): \(keys.count)")
        total += keys.count
    }
    print("total: \(total)")
}
