//
//  PlaceIndex.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 22 November 2025.
//  Last changed on 22 February 2026.
//

import Foundation

/// Place index key; combines an event kind with a name part.
struct PlaceIndexKey: Hashable {
    let part: String  // Part name.
    let event: EventKind  // Event kind.
}

/// Place index for DeadEnds database.
final public class PlaceIndex {

    /// Index is a map from place index keys (part x event kind) to sets of record keys.
    private(set) var index: [PlaceIndexKey : Set<RecordKey>] = [:]  // Representation.

    /// Add entries to the index; place is expanded into its parts.
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

/// Break a place value string into components; further processing
/// is done in _______.
private func placeComponents(_ raw: String) -> [String] {

    // Start with the value of a place node; lowercase it and clean whitespace.
    var string = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    while string.contains("  ") { string = string.replacingOccurrences(of: "  ", with: " ") }

    // Split the string around commas and or's.
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
    // orParts is an array of components from the original value. Remove any leading 'noise' words
    // from each component.
    let noisePrefixes: [String] = [
        "prob ", "probable ", "probably ", "maybe ",
        "poss ", "possible ", "possibly ",
        "near ", "about ", "abt ", "circa "
    ]
    for var part in orParts {
        var changed = true
        while changed {
            changed = false
            for prefix in noisePrefixes where part.hasPrefix(prefix) {
                part = part.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces)
                changed = true
            }
        }
        if part.isEmpty { /* How do I remove a part? */ print("How do I remove a part") }
    }

    // Drop certain country words.
    let dropCountries: Set<String> = [
        "united states", "united states of america",
        "usa", "u.s.", "u.s.a", "us",
        "canada"
    ]
    for part in orParts {
        if dropCountries.contains(part) { print("How do I remove a part") }
    }
    return orParts
}

/// Get the place keys, one or more, for a place component.
private func placeKeys(forComponent part: String) -> [String] {

    let jurisdiction: Set<String> = ["county","city", "commonwealth", "borough", "district", "municipality", "province", "nation", "state", "parish", "colony", "village", "town"]
    let glue: Set<String> = ["of","the"]

    let full = part.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !full.isEmpty else { return [] }

    let tokens = full.split(whereSeparator: { $0.isWhitespace }).map(String.init)
    guard !tokens.isEmpty else { return [full] }

    var out: [String] = [full]  // Keep full phrase.

    if let first = tokens.first, jurisdiction.contains(first), tokens.count > 1 {  // Handle prefixes.
        var core = Array(tokens.dropFirst())
        while let t = core.first, glue.contains(t) { core.removeFirst() }
        if !core.isEmpty {
            out.append(core.joined(separator: " "))
            out.append(contentsOf: core.filter { !glue.contains($0) && !jurisdiction.contains($0) })
        }
    }
    else if let last = tokens.last, jurisdiction.contains(last), tokens.count > 1 {  // Handle suffixes.
        let core = Array(tokens.dropLast())
        out.append(core.joined(separator: " "))
        out.append(contentsOf: core.filter { !glue.contains($0) && !jurisdiction.contains($0) })
    }
    else {  // Normal, no prefix, no suffix case.
        out.append(contentsOf: tokens.filter { !glue.contains($0) && !jurisdiction.contains($0) })
    }

    var seen = Set<String>()  // Dedupe.
    return out.filter { seen.insert($0).inserted }
}

/// Get the canonical parts of a Gedcom PLAC value.
func oldplaceParts(_ raw: String) -> [String] {
    placeComponents(raw).flatMap(placeKeys(forComponent:))
}

/// Builds a PlaceIndex from a RecordList.
public func buildPlaceIndex(from recordIndex: RecordIndex) -> PlaceIndex {
    let placeIndex = PlaceIndex()

    for (_, root) in recordIndex {
        switch root.tag {
        case GedcomTag.indi.rawValue:
            if let person = Person(root) { placeIndex.indexPlaces(from: person) }
        case GedcomTag.fam.rawValue:
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
    
    /// Debug method that prints the contents of a PlaceIndex.
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

    /// Show the frequency table of a place index.
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

/// Find canonical search keys for a Gedcom PLAC value.
/// Returns expanded keys suitable for indexing/search.
func placeParts(_ raw: String) -> [String] {

    var s = raw.lowercased()
        .trimmingCharacters(in: .whitespacesAndNewlines)
    while s.contains("  ") {
        s = s.replacingOccurrences(of: "  ", with: " ")
    }

    // -------------------------------
    // Stage 2: Strip leading noise qualifiers
    // -------------------------------

    let noisePrefixes: [String] = [
        "prob ", "probable ", "probably ", "maybe ",
        "poss ", "possible ", "possibly ",
        "near ", "about ", "abt ", "circa "
    ]

    var changed = true
    while changed {
        changed = false
        for prefix in noisePrefixes where s.hasPrefix(prefix) {
            s = s.dropFirst(prefix.count)
                .trimmingCharacters(in: .whitespaces)
            changed = true
        }
    }

    // -------------------------------
    // Stage 3: Split on commas
    // -------------------------------

    let commaParts = s
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }

    // Expand " or " alternatives
    var components: [String] = []
    for part in commaParts {
        if part.contains(" or ") {
            components.append(contentsOf:
                part.split(separator: " or ")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            )
        } else {
            components.append(part)
        }
    }

    // -------------------------------
    // Stage 4: Drop countries
    // -------------------------------

    let dropCountries: Set<String> = [
        "united states", "united states of america",
        "usa", "u.s.", "u.s.a", "us",
        "canada"
    ]

    // -------------------------------
    // Stage 5: Expand jurisdiction variants
    // -------------------------------

    func expandedKeys(from part: String) -> [String] {

        let p = part.trimmingCharacters(in: .whitespaces)
        guard !p.isEmpty else { return [] }
        if dropCountries.contains(p) { return [] }

        var out: [String] = [p]  // Always keep original phrase

        func wordCount(_ s: String) -> Int {
            s.split(separator: " ").count
        }

        func maybeAddVariant(_ s: String) {
            let v = s.trimmingCharacters(in: .whitespaces)
            guard !v.isEmpty else { return }
            // Prevent overly lossy variants like "iron city" → "iron"
            guard wordCount(v) >= 2 else { return }
            out.append(v)
        }

        // Jurisdiction prefixes
        let prefixRules = [
            "city of ",
            "county of ",
            "state of ",
            "province of ",
            "commonwealth of "
        ]

        for pref in prefixRules where p.hasPrefix(pref) {
            maybeAddVariant(String(p.dropFirst(pref.count)))
        }

        // Jurisdiction suffixes
        let suffixRules = [
            " city",
            " county",
            " province",
            " state",
            " commonwealth",
            " colony"
        ]

        for suf in suffixRules where p.hasSuffix(suf) {
            maybeAddVariant(String(p.dropLast(suf.count)))
        }

        return out
    }

    // -------------------------------
    // Stage 6: Build final key list
    // -------------------------------

    var allKeys: [String] = []

    for comp in components {
        allKeys.append(contentsOf: expandedKeys(from: comp))
    }

    // Deduplicate while preserving order
    var seen = Set<String>()
    return allKeys.filter { seen.insert($0).inserted }
}
