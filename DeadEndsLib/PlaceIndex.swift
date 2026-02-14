//
//  PlaceIndex.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 22 November 2025.
//  Last changed on 13 February 2026.
//

import Foundation

/// Place index key; combines event kind with canonical name part.
struct PlaceIndexKey: Hashable {
    let part: String  // Canonical part name.
    let event: EventKind  // Event kind.
}

/// Place index for DeadEnds database.
final public class PlaceIndex {

    private(set) var index: [PlaceIndexKey : Set<RecordKey>] = [:]  // Representation.

    /// Add entries to the place index; canonicalize place to parts.
    public func add(place: String, event: EventKind, recordKey: RecordKey) {
        let parts = placeParts(place)
        guard !parts.isEmpty else { return }
        for part in parts {
            add(part: part, event: event, recordKey: recordKey)
        }
    }

    /// Add entry to the place index.
    func add(part: String, event: EventKind, recordKey: RecordKey) {
        index[PlaceIndexKey(part: part, event: event), default: Set()].insert(recordKey)
    }

    /// Remove entries from the place index; canonicalize place into parts.
    func remove(place: String, event: EventKind, recordKey: RecordKey) {
        let parts = placeParts(place)
        for part in parts {
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
        let parts = placeParts(place)
        for part in parts {
            let recordSet = index[PlaceIndexKey(part: part, event: event)] ?? []
            if recordSet.count > 0 {
                partMap[part] = recordSet
            }
        }
        return partMap
    }

    /// Return set of record keys that match an event place part.
    func recordKeys(part: String, event: EventKind) -> Set<RecordKey> {
        return index[PlaceIndexKey(part: part, event: event)] ?? []
    }
}

/// Collect all PLAC values, at any level, and return them as a string array.
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

/// Find the canonical parts of a Gedcom PLAC value.
func placeParts(_ raw: String) -> [String] {

    var string = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

    let noiseWords = [ // Words and phrases to strip.
        "prob ", "probable ", "probably ", "maybe ",
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

