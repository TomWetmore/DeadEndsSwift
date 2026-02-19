//
//  Search.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 26 November 2025.
//  Last changed on 18 February 2026.
//

import Foundation

/// Person search criteria.
public struct SearchCriteria {
    
    public var name: String?
    public var birthYearRange: ClosedRange<Year>?
    public var deathYearRange: ClosedRange<Year>?
    public var birthPlace: String?
    public var deathPlace: String?

    public var placeParts: [String]?  // Deprecated -- so I don't have to change the panel yet.

    /// Create search criteria struct.
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

/// Score reason.
public enum ScoreReason: String {

    case name
    case birthDate
    case deathDate
    case birthPlace
    case deathPlace
}

/// Person search result.
public struct SearchResult: Identifiable, CustomStringConvertible {
    
    public let key: RecordKey
    public var score: Int
    public var reasons: Set<ScoreReason>
    
    public var id: RecordKey { key }

    /// Return description of result.
    public var description: String {
        let reasonList = reasons
            .map { $0.rawValue }.sorted().joined(separator: ", ")
        return "SearchResult(key: \(key), score: \(score), reasons: [\(reasonList)])"
    }

    /// Add score to result.
    mutating func add(_ points: Int, reason: ScoreReason) {
        score += points
        reasons.insert(reason)
    }

    /// Compare search results.
    func compare(to other: SearchResult, in index: RecordIndex) -> ComparisonResult {

        if score < other.score { return .orderedDescending }
        if score > other.score { return .orderedAscending }
        
        let personOne = index.person(for: key)
        let personTwo = index.person(for: other.key)
        return personOne!.compare(to: personTwo!, in: index)
    }

    /// Return full description of result.
    public func fullDescription(in index: RecordIndex) -> String {

        guard let person = index.person(for: key) else { return "<unknown>" }
        let name = person.displayName()
        let birth = person.birthEvent?.summary ?? "-"
        let death = person.deathEvent?.summary ?? "-"
        let reasonList = reasons
            .map { $0.rawValue }
            .sorted()
            .joined(separator: ", ")
        return "\(name) \(key)  \(score)  b. \(birth) d. \(death) {\(reasonList)}"
    }
}

public typealias SearchResults = [RecordKey : SearchResult]


private struct CandidateSets {
    
    let nameSet: Set<RecordKey>
    let birthDateSet: Set<RecordKey>
    let deathDateSet: Set<RecordKey>
    let birthPartSets: [String : Set<RecordKey>]
    let deathPartSets: [String : Set<RecordKey>]
}

/// Update search result.
fileprivate func updateResult(_ results: inout SearchResults, _ key: RecordKey,
                              score: Int, reason: ScoreReason) {
    if var result = results[key] {
        result.add(score, reason: reason)
        results[key] = result
    }
}

    extension Database {

        /// Search database for persons based on search criteria.
        public func searchPersons(_ criteria: SearchCriteria) -> [SearchResult] {

            // Gather all the matching record key sets.
            var nameSet: Set<RecordKey> = []
            var birthDateSet: Set<RecordKey> = []
            var deathDateSet: Set<RecordKey> = []
            var birthPartSets: [String : Set<RecordKey>] = [:]
            var deathPartSets: [String : Set<RecordKey>] = [:]

            if let name = criteria.name {
                nameSet = Set(personKeys(forName: name))
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
            var results: SearchResults = [:]
            if !nameSet.isEmpty {  // If there are names do name-centric search.
                results = nameBasedSearch(candidateSets)
            } else {
                results = datePlaceBasedSearch(candidateSets)
            }
            return results.values.sorted {  // Convert from SearchResults to ordered [SearchResult] array.
                $0.compare(to: $1, in: recordIndex) == .orderedAscending
            }
        }
    }

//    private func ordered(_ results: SearchResults) -> [SearchResult] {
//        results.values.sorted {
//            $0.compare(to: $1, in: recordIndex) == .orderedAscending
//        }
//    }

    /// Get search results if criteria includes a name.
    private func nameBasedSearch(_ candidateSets: CandidateSets) -> SearchResults {

        var results: SearchResults = [:]
        let personSet = candidateSets.nameSet
        guard !personSet.isEmpty else { return [:] } // Should not happen.
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
        for (_, keySet) in candidateSets.birthPartSets {
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

    /// Get search results if criteria does not include name.
    private func datePlaceBasedSearch(_ candidateSets: CandidateSets) -> SearchResults {

        var results: SearchResults = [:]
        results.reserveCapacity(250)  // Do better job with capacity.

        // Get buckets for places.
        let birthPlaceBuckets: [Set<RecordKey>] =
            bucketsByMatchCount(candidateSets.birthPartSets.values)
        let deathPlaceBuckets: [Set<RecordKey>] =
            bucketsByMatchCount(candidateSets.deathPartSets.values)

        return results
    }
//}

/// Place keys in array of record key sets based on the number of their occurrences.
func bucketsByMatchCount<C: Collection>(_ sets: C) -> [Set<RecordKey>]
    where C.Element == Set<RecordKey> {

    var counts: [RecordKey: Int] = [:]

    for set in sets {
        for key in set {
            counts[key, default: 0] += 1
        }
    }
    let n = sets.count
    var buckets = Array(repeating: Set<RecordKey>(), count: n + 1)
    for (key, count) in counts {
        buckets[count].insert(key)
    }
    return buckets
}

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



// MARK: - Candidate helpers (reuse your indexes)

//    private func keysForYears(_ range: ClosedRange<Year>, event: EventKind) -> Set<RecordKey> {
//        var out = Set<RecordKey>()
//        for y in range {
//            if let s = dateIndex.recordKeys(year: y, event: event) {
//                out.formUnion(s)
//            }
//        }
//        return out
//    }

//    private func keysForPlaceParts(_ parts: [String], events: [EventKind]) -> Set<RecordKey> {
//        var out = Set<RecordKey>()
//        for p in parts {
//            for ev in events {
//                let k = PlaceIndexKey(part: p, event: ev)
//                out.formUnion(placeIndex.index[k] ?? [])
//            }
//        }
//        return out
//    }

//    private func scoreName(_ query: String, person: Person) -> Int {
//        let q = query.lowercased()
//        let name = person.displayName(upSurname: true).lowercased()
//
//        if name == q { return 80 }
//        if name.contains(q) { return 40 }
//
//        // Token bonus (very crude, but useful)
//        let tokens = q.split(whereSeparator: { $0 == " " || $0 == "," }).map(String.init)
//        var s = 0
//        for tok in tokens where !tok.isEmpty {
//            if name.contains(tok) { s += 15 }
//        }
//        return s
//    }

//    private func year(of person: Person, kind: EventKind, in range: ClosedRange<Year>) -> Bool {
//        // Use whatever you have; if you can only access eventSummary, you may need a year extractor.
//        // Ideally: person.birthEvent?.year, person.deathEvent?.year etc.
//        // Placeholder: return false if unknown.
//        guard let y = person.year(kind: kind) else { return false } // implement or adapt
//        return range.contains(y)
//    }

