//
//  PlaceIndex.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 22 November 2025.
//  Last changed on 24 February 2026.
//

import Foundation

/// Place index key; combines a place part with an event kind.
struct PlaceIndexKey: Hashable {
    let part: String
    let event: EventKind
}

/// Place index for DeadEnds database.
final public class PlaceIndex {

    /// Map place index keys to sets of record keys.
    private(set) var index: [PlaceIndexKey : Set<RecordKey>] = [:]  // Representation.

    /// Add entries to the index; place is expanded into parts.
    public func add(place: String, event: EventKind, recordKey: RecordKey) {
        for part in placeParts(place) {
            add(part: part, event: event, recordKey: recordKey)
        }
    }

    /// Add entry to the index; part is a component of a place value.
    fileprivate func add(part: String, event: EventKind, recordKey: RecordKey) {
        index[PlaceIndexKey(part: part, event: event), default: Set()].insert(recordKey)
    }

    /// Remove entries from the index; place is expanded into its parts.
    func remove(place: String, event: EventKind, recordKey: RecordKey) {
        for part in placeParts(place) {
            let placeIndexKey = PlaceIndexKey(part: part, event: event)
            guard var keys = index[placeIndexKey] else { continue }
            keys.remove(recordKey)
            if keys.isEmpty { index.removeValue(forKey: placeIndexKey) }
            else { index[placeIndexKey] = keys }
        }
    }

    /// Return dictionary mapping parts to record sets.
    func recordKeys(place: String, event: EventKind) -> [String : Set<RecordKey>] {
        var partMap: [String : Set<RecordKey>] = [:]
        for part in placeParts(place) {
            let recordSet = index[PlaceIndexKey(part: part, event: event)] ?? []
            if recordSet.count > 0 {
                partMap[part] = recordSet
            }
        }
        return partMap
    }

    /// Return set of record keys that match an event kind and place part.
    func recordKeys(part: String, event: EventKind) -> Set<RecordKey> {
        return index[PlaceIndexKey(part: part, event: event)] ?? []
    }
}

/// Collect all PLAC values, at any level, and return them as a string array.
//func collectAllPlaceStrings(from recordIndex: RecordIndex) -> [String] {
//    var results: [String] = []
//    var records = 0
//
//    for (_, root) in recordIndex {
//        records += 1
//        for node in root.descendants() {
//            if node.tag == "PLAC", let value = node.val {
//                results.append(value)
//            }
//        }
//    }
//    print("collected \(results.count) PLAC values across \(records) records")
//    return results
//}

/// Get the canonical parts of a Gedcom PLAC value.
func placeParts(_ raw: String) -> [String] {
    placeComponents(raw).flatMap(placeKeys(phrase:))
}

/// Break a place value string into components; further processing done in placeKeys.
private func placeComponents(_ raw: String) -> [String] {

    // Lowercase and clean whitespace.
    var string = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    while string.contains("  ") { string = string.replacingOccurrences(of: "  ", with: " ") }

    // Split value around commas and or's.
    let commaParts = string
        .split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
    var orParts: [String] = []
    for part in commaParts {
        if part.contains(" or ") {
            orParts.append(contentsOf:
                            part.split(separator: " or ").map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            )
        } else {
            orParts.append(part)
        }
    }
    // orParts is an array of components from the original value. Remove leading 'noise' words
    // and certain country parts from the components .
    let noisePrefixes: [String] = [
        "probable ", "probably ", "prob ", "maybe ",
        "possible ", "possibly ", "poss ",
        "near ", "about ", "abt ", "circa "
    ]
    let dropCountries: Set<String> = [
        "united states", "united states of america",
        "usa", "u.s.", "u.s.a", "us",
        "canada"
    ]
    let stripped = orParts.compactMap { original -> String? in
        var part = original
        var changed = true
        while changed {
            changed = false
            for prefix in noisePrefixes where part.hasPrefix(prefix) {
                part = part.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces)
                changed = true
            }
        }
        return part.isEmpty ? nil : part
    }

    let withoutCountries = stripped.filter { !dropCountries.contains($0) }

    // Keep countries only if they were the only remaining parts.
    orParts = withoutCountries.isEmpty ? stripped : withoutCountries
    return orParts
}

/// Convert place phrases to final form.
private func placeKeys(phrase: String) -> [String] {

    var results: [String] = [phrase]  // Keep original phrase.

    /// Helper functions.
    func wordCount(_ phrase: String) -> Int { phrase.split(separator: " ").count }

    func maybeAddVariant(_ phrase: String) {
        if phrase.isEmpty { return }
        if wordCount(phrase) < 1 { return }
        results.append(phrase)
    }
    let prefixes = [
        "city of ",
        "county of ",
        "state of ",
        "province of ",
        "commonwealth of "
    ]
    for prefix in prefixes where phrase.hasPrefix(prefix) {
        maybeAddVariant(String(phrase.dropFirst(prefix.count)))
    }
    let suffixes = [
        " city",
        " county",
        " province",
        " state",
        " commonwealth",
        " colony"
    ]
    for suffix in suffixes where phrase.hasSuffix(suffix) {
        maybeAddVariant(String(phrase.dropLast(suffix.count)))
    }
    return Array(Set(results)) // Dedupe.
}

/// Builds a PlaceIndex from a RecordList.
public func buildPlaceIndex(from recordIndex: RecordIndex) -> PlaceIndex {
    let placeIndex = PlaceIndex()

    for (_, root) in recordIndex {
        switch root.tag {
        case GedcomTag.INDI:
            if let person = Person(root) { placeIndex.indexPlaces(from: person) }
        case GedcomTag.FAM:
            if let family = Family(root) { placeIndex.indexPlaces(from: family) }
        default: break
        }
    }
    return placeIndex
}

extension PlaceIndex {

    /// Index the place nodes in an event tree.
    private func indexPlaces(in eventNode: GedcomNode, kind: EventKind, recordKey: RecordKey) {
        for placeNode in eventNode.kids(withTag: GedcomTag.plac.rawValue) {
            guard let place = placeNode.val else { continue }
            add(place: place, event: kind, recordKey: recordKey)
        }
    }

    /// Index the birth and death places of a person.
    func indexPlaces(from person: Person) {
        guard let key = person.root.key else { return }
        for eventNode in person.root.kids where eventNode.hasTag(.birt) || eventNode.hasTag(.deat) {
            let kind: EventKind = eventNode.hasTag(.birt) ? .birth : .death
            indexPlaces(in: eventNode, kind: kind, recordKey: key)
        }
    }

    /// Index the marriage places of a family.
    func indexPlaces(from family: Family) {
        guard let key = family.root.key else { return }
        for eventNode in family.root.kids where eventNode.hasTag(.marr) {
            indexPlaces(in: eventNode, kind: .marriage, recordKey: key)
        }
    }
}

extension PlaceIndex {

    /// Print contents of a PlaceIndex; for testing and debug.
    func showContents(using recordIndex: RecordIndex) {
        let sortedEntries = index.sorted { $0.key.part < $1.key.part }

        for (placeKey, recordKeys) in sortedEntries {
            for key in recordKeys.sorted() {
                if let person = recordIndex.person(for: key) {
                    print("\(placeKey.part): \(person.displayName()) [\(key)]")
                }
                else if recordIndex.family(for: key) != nil {
                    print("\(placeKey.part): Family \(key)")
                }
                else {
                    print("\(placeKey.part): ??? (\(key))")
                }
            }
        }
    }

    /// Show the frequency table of a place index; for testing and debug.
    public func showPlaceFrequencyTable() {
        var total: Int = 0
        let sorted = index.sortedByValueCount()
        for (part, keys) in sorted {
            print("\(part): \(keys.count)")
            total += keys.count
        }
        print("total: \(total)")
    }
}

extension Dictionary where Value: Collection {

    func sortedByValueCount(descending: Bool = true) -> [(Key, Value)] {
        self.sorted {
            descending
            ? $0.value.count > $1.value.count
            : $0.value.count < $1.value.count
        }
    }
}

public func testPlaceIndexing() {
    let values = ["New London, New London County, State of Connecticut, United States",
                  "near Pittsburgh, Pennsylvania, USA",
                  "New London, Connecticut Colony",
                  "St. Mary's Bay, Digby County, Nova Scotia, Canada"
                  ]

    for value in values {
        let parts = placeParts(value)
        print("\(value): {\(parts)}")
    }
}
