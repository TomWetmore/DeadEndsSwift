//
//  PlaceIndex.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 22 November 2025.
//  Last changed on 27 August 2026.
//
//  Birth, death and marriage places are indexed. Keys combine
//  place parts and event types. Values are the sets of
//  record keys of persons and families that have the place.


import Foundation

/// Place index keys combine a place part with an event kind.
struct PlaceKey: Hashable {

    let part: String
    let event: EventKind
}

/// Place index for DeadEnds database. The index is built when
/// the database is built. It is modified when the user changes
/// the database.
final public class PlaceIndex {

    /// Dictionary that holds the index.
    private(set) var index: [PlaceKey : Set<RecordKey>] = [:]

    /// Number of place keys in the index.
    public var count: Int { index.count }

    /// Add entries to the index. Place is the value of a PLAC node. It
    /// is expanded into parts which are added individually.
    public func add(place: String, event: EventKind, recordKey: RecordKey) {

        for part in placeParts(place) {
            add(part: part, event: event, recordKey: recordKey)
        }
    }

    /// Add an entry to the index; part is a component extracted from
    /// a PLAC value.
    public func add(part: String, event: EventKind, recordKey: RecordKey) {

        index[PlaceKey(part: part, event: event), default: Set()].insert(recordKey)
    }

    /// Remove entries from the index; place is expanded into parts
    /// that are removed individually.
    func remove(place: String, event: EventKind, recordKey: RecordKey) {

        for part in placeParts(place) {
            remove(part: part, event: event, recordKey: recordKey)
        }
    }

    func remove(part: String, event: EventKind, recordKey: RecordKey) {

        let placeKey = PlaceKey(part: part, event: event)
        guard var keys = index[placeKey] else { return }
        keys.remove(recordKey)
        if keys.isEmpty { index.removeValue(forKey: placeKey) }
        else { index[placeKey] = keys }
    }

    /// Expand a PLAC value into parts and return the array of dictionaries that
    /// map those parts to record keys.
    func recordKeys(place: String, event: EventKind) -> [String : Set<RecordKey>] {

        var partMap: [String : Set<RecordKey>] = [:]
        for part in placeParts(place) {
            let recordSet = index[PlaceKey(part: part, event: event)] ?? []
            if recordSet.count > 0 {
                partMap[part] = recordSet
            }
        }
        return partMap
    }

    /// Return the set of record keys that match a specific part and event.
    func recordKeys(part: String, event: EventKind) -> Set<RecordKey> {

        return index[PlaceKey(part: part, event: event)] ?? []
    }
}

/// Return the array of parts extracted from a Gedcom PLAC value. Both placeComponents
/// and placeKeys perform non-trivial text manipulation.
func placeParts(_ raw: String) -> [String] {

    placeComponents(raw).flatMap(placeKeys(phrase:))
}

/// Expand a PLAC value into the initial set of components.
private func placeComponents(_ raw: String) -> [String] {

    // Lowercase and clean whitespace.
    var string = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    while string.contains("  ") { string = string.replacingOccurrences(of: "  ", with: " ") }

    // Split value around commas and brackets.
     let commaParts = string
         .split { ",()[]{}".contains($0) }
         .map { $0.trimmingCharacters(in: .whitespaces) }
         .filter { !$0.isEmpty }

    // Split values around " or ".
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
    // Strip noise.
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

    // Check if country names should be stripped.
    let withoutCountries = stripped.filter { !dropCountries.contains($0) }

    // Keep countries if they are the only remaining parts.
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
            placeIndex.indexPlaces(from: Person(root))
        case GedcomTag.FAM:
            placeIndex.indexPlaces(from: Family(root))
        default: break
        }
    }
    //placeIndex.showContents(using: recordIndex) // DEBUG
    return placeIndex
}

extension PlaceIndex {

    /// Index the place (PLAC) nodes in an event tree.
    private func indexPlaces(in eventNode: GedcomNode, kind: EventKind, recordKey: RecordKey) {

    // Find every PLAC node in the event.
        for placeNode in eventNode.kids(withTag: GedcomTag.PLAC) {
            guard let place = placeNode.val else { continue }
            add(place: place, event: kind, recordKey: recordKey)
        }
    }

    /// Index the birth and death places of a person.
    func indexPlaces(from person: Person) {

        // Get the person's key.
        guard let key = person.root.key else { return }

        // Find every BIRT and DEAT node in the person.
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
                  "St. Mary's Bay, Digby County, Nova Scotia, Canada",
                  "Saint John, Kings County, New Brunswick"
                  ]

    for value in values {
        let parts = placeParts(value)
        print("\(value): {\(parts)}")
    }
}
