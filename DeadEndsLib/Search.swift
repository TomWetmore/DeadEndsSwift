//
//  Search.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 26 November 2025.
//  Last changed on 13 February 2026.
//

import Foundation

/// Person search criteria.
public struct SearchCriteria {
    public var name: String?
    public var birthYearRange: ClosedRange<Year>?
    public var deathYearRange: ClosedRange<Year>?
    public var birthPlace: String?
    public var deathPlace: String?

    public var placeParts: [String]?  // Deprecated so I don't have to change the panel yet.

    /// Create a search criteria struct.
    public init(name: String? = nil, birthYearRange: ClosedRange<Year>? = nil,
                deathYearRange: ClosedRange<Year>? = nil, birthPlace: String? = nil, deathPlace: String? = nil) {
        self.name = name
        self.birthYearRange = birthYearRange
        self.deathYearRange = deathYearRange
        self.birthPlace = birthPlace
        self.deathPlace = deathPlace
        self.placeParts = []  // Deprecated.
    }
}

/// Reasons for a score.
public enum ScoreReason: String {
    case name
    case birthDate
    case deathDate
    case birthPlace
    case deathPlace
}

/// Person search result.
public struct SearchResult: Identifiable {
    public let key: RecordKey
    public var score: Int
    public var reasons: Set<ScoreReason>
    public var id: RecordKey { key }

    mutating func add(_ points: Int, reason: ScoreReason) {
        score += points
        reasons.insert(reason)
    }

}

public typealias SearchResults = [RecordKey : SearchResult]

struct CandidateSets {
    let nameSet: Set<RecordKey>
    let birthDateSet: Set<RecordKey>
    let deathDateSet: Set<RecordKey>
    let birthPartSets: [String : Set<RecordKey>]
    let deathPartSets: [String : Set<RecordKey>]
}

fileprivate func updateResult(_ results: inout SearchResults, _ key: RecordKey,
                              score: Int, reason: ScoreReason) {
    if var result = results[key] {
        result.add(score, reason: reason)
        results[key] = result
    }
}

extension Database {

   /// Search the database for persons based on search criteria.
    public func searchPersons(_ criteria: SearchCriteria) -> SearchResults {

        // Gather all the record sets.
        var nameSet: Set<RecordKey> = []
        var birthDateSet: Set<RecordKey> = []
        var deathDateSet: Set<RecordKey> = []
        var birthPartSets: [String : Set<RecordKey>] = [:]
        var deathPartSets: [String : Set<RecordKey>] = [:]

        if let name = criteria.name {
            nameSet = nameIndex.recordKeys(forName: name)
        }
        if let range = criteria.birthYearRange {
            birthDateSet = dateIndex.recordKeys(in: range, event: .birth)
        }
        if let range = criteria.deathYearRange {
            deathDateSet = dateIndex.recordKeys(in: range, event: .death)
        }
        if let place = criteria.birthPlace {
            birthPartSets = placeIndex.recordKeys(place: place, event: .birth)
        }
        if let place = criteria.deathPlace {
            deathPartSets = placeIndex.recordKeys(place: place, event: .death)
        }

        let candidateSets = CandidateSets(nameSet: nameSet, birthDateSet: birthDateSet,
                                          deathDateSet: deathDateSet, birthPartSets: birthPartSets,
                                          deathPartSets: deathPartSets)

        // If there are any names do a name-centric search.
        if !nameSet.isEmpty {
            return nameBasedSearch(candidateSets)
        }

        // There are no persons so do more complex search.
        // WRITE ME!!!
        return [:]
    }


        // Score the candidates
        //var results: [SearchResult] = []
        //results.reserveCapacity(candidates.count)
//
//        for key in candidates {
//            guard let person = recordIndex.person(for: key) else { continue }
//
//            var score = 0
//            var reasons: [String] = []
//
//            // Name scoring (fuzzy-ish)
//            if let name = trimmed(criteria.name) {
//                let s = scoreName(name, person: person)
//                if s > 0 { score += s; reasons.append("name+\(s)") }
//            }
//
//            // Birth year scoring (strong)
//            if let r = criteria.birthYearRange {
//                if year(of: person, kind: .birth, in: r) {
//                    score += 40
//                    reasons.append("birth in range")
//                } else {
//                    // choose: either penalize or hard-filter. Start with mild penalty.
//                    score -= 10
//                }
//            }
//
//            // Death year scoring (strong)
//            if let r = criteria.deathYearRange {
//                if year(of: person, kind: .death, in: r) {
//                    score += 40
//                    reasons.append("death in range")
//                } else {
//                    score -= 10
//                }
//            }
//
//            // Place scoring (increment per matching component)
//            if let parts = normalizedParts(criteria.placeParts), !parts.isEmpty {
//                let s = scorePlaces(parts, person: person)
//                if s > 0 { score += s; reasons.append("place+\(s)") }
//            }
//
//            // Threshold: require positive score (tune later)
//            if score > 0 {
//                results.append(SearchResult(id: key, key: key, score: score, reasons: reasons))
//            }
//        }
//
//        // 3) Sort by score then name
//        results.sort {
//            if $0.score != $1.score { return $0.score > $1.score }
//            let na = recordIndex.person(for: $0.key)?.displayName(upSurname: true) ?? $0.key
//            let nb = recordIndex.person(for: $1.key)?.displayName(upSurname: true) ?? $1.key
//            return na.localizedCaseInsensitiveCompare(nb) == .orderedAscending
//        }
//
//        return [:]  // Until we get to it.
//    }

    /// Compute person search results when search criteria includes a name.
    private func nameBasedSearch(_ candidateSets: CandidateSets) -> SearchResults {

        var results: SearchResults = [:]
        let personSet = candidateSets.nameSet
        guard !personSet.isEmpty else { return results } // Should not happen.
        results.reserveCapacity(personSet.count)

        for key in personSet {  // Create search result for each person.
            results[key] = SearchResult(key: key, score: 0, reasons: [.name])
        }
        for key in personSet.intersection(candidateSets.birthDateSet) {
            updateResult(&results, key, score: 40, reason: .birthDate)
        }
        for key in personSet.intersection(candidateSets.deathDateSet) {
            updateResult(&results, key, score: 40, reason: .deathDate)
        }
        for (_, keySet) in candidateSets.deathPartSets {
            for key in personSet.intersection(keySet) {
                updateResult(&results, key, score: 20, reason: .birthPlace)
            }
        }
        for (_, keySet) in candidateSets.deathPartSets {
            for key in personSet.intersection(keySet) {
                updateResult(&results, key, score: 20, reason: .deathPlace)
            }
        }
        return results
    }

    // MARK: - Candidate helpers (reuse your indexes)

    private func keysForYears(_ range: ClosedRange<Year>, event: EventKind) -> Set<RecordKey> {
        var out = Set<RecordKey>()
        for y in range {
            if let s = dateIndex.recordKeys(year: y, event: event) {
                out.formUnion(s)
            }
        }
        return out
    }

    private func keysForPlaceParts(_ parts: [String], events: [EventKind]) -> Set<RecordKey> {
        var out = Set<RecordKey>()
        for p in parts {
            for ev in events {
                let k = PlaceIndexKey(part: p, event: ev)
                out.formUnion(placeIndex.index[k] ?? [])
            }
        }
        return out
    }

    private func scoreName(_ query: String, person: Person) -> Int {
        let q = query.lowercased()
        let name = person.displayName(upSurname: true).lowercased()

        if name == q { return 80 }
        if name.contains(q) { return 40 }

        // Token bonus (very crude, but useful)
        let tokens = q.split(whereSeparator: { $0 == " " || $0 == "," }).map(String.init)
        var s = 0
        for tok in tokens where !tok.isEmpty {
            if name.contains(tok) { s += 15 }
        }
        return s
    }

    private func year(of person: Person, kind: EventKind, in range: ClosedRange<Year>) -> Bool {
        // Use whatever you have; if you can only access eventSummary, you may need a year extractor.
        // Ideally: person.birthEvent?.year, person.deathEvent?.year etc.
        // Placeholder: return false if unknown.
        guard let y = person.year(kind: kind) else { return false } // implement or adapt
        return range.contains(y)
    }

    private func scorePlaces(_ parts: [String], person: Person) -> Int {
        // Start crude: check if the person’s birth/death place strings contain each part
        // Better later: canonicalize person places into parts and compare sets.
        var s = 0
        let birth = (person.place(kind: .birth) ?? "").lowercased()
        let death = (person.place(kind: .death) ?? "").lowercased()

        for p in parts {
            if birth.contains(p) || death.contains(p) { s += 12 }
        }
        return s
    }
}

/// TO KEEP COMPILER HAPPY FOR NOW.
extension Person {

    func year(kind: EventKind) -> Year? {
        return 1949
    }
    func place(kind: EventKind) -> String? {
        return "New London"
    }
}


