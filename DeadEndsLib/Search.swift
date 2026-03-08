//
//  Search.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 26 November 2025.
//  Last changed on 18 February 2026.

/// Search.swift has the code for searching the database for persons.
/// Searching is done using names, years that events occurred, and
/// parts of names mentioned in event places.
/// Searching is done by scoring criteria the user provides. Criteria
/// include names, years of events, and parts mentioned in event places.
///
/// The overall search process consists of a criteria being provided,
/// the search occurring, and the results being returned, sorted by
/// score.

import Foundation

/// Person search criteria.
public struct SearchCriteria {
    public var name: String?
    public var birthYearRange: ClosedRange<Year>?
    public var deathYearRange: ClosedRange<Year>?
    public var birthPlace: String?
    public var deathPlace: String?

    /// Create search criteria struct.
    public init(name: String? = nil, birthYearRange: ClosedRange<Year>? = nil,
                deathYearRange: ClosedRange<Year>? = nil, birthPlace: String? = nil, deathPlace: String? = nil) {
        self.name = name
        self.birthYearRange = birthYearRange
        self.deathYearRange = deathYearRange
        self.birthPlace = birthPlace
        self.deathPlace = deathPlace
    }
}

/// Person search result, consisting of a record key, a score, and set of score reasons.
public struct SearchResult: Identifiable, CustomStringConvertible {
    public let key: RecordKey
    public var score: Int
    public var reasons: [String]

    public var id: RecordKey { key }

    /// Return description of search result.
    public var description: String {
        let reasonList = reasons
            .map { $0 }.sorted().joined(separator: ", ")
        return "SearchResult(key: \(key), score: \(score), reasons: [\(reasonList)])"
    }

    /// Add score to search result.
    mutating func add(_ points: Int, reason: String) {
        score += points
        reasons.append(reason)
    }

    /// Compare search results; used to sort results.
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
            .map { $0 }
            .sorted()
            .joined(separator: ", ")
        return "\(name) \(key)  \(score)  b. \(birth) d. \(death) {\(reasonList)}"
    }
}

/// Map that collects the search results.
public typealias SearchResults = [RecordKey : SearchResult]


/// Candidate sets hold the record keys of persons who match
/// the different search criteria.
private struct CandidateSets {
    let nameSet: Set<RecordKey>
    let birthDateSet: Set<RecordKey>
    let deathDateSet: Set<RecordKey>
    let birthPartSets: [String : Set<RecordKey>]
    let deathPartSets: [String : Set<RecordKey>]
}

/// Update search result.
fileprivate func updateResult(_ results: inout SearchResults, _ key: RecordKey,
                              score: Int, reason: String) {
    if var result = results[key] {
        result.add(score, reason: reason)
        results[key] = result
    } else {
        results[key] = SearchResult(key: key, score: score, reasons: [reason])
    }
}

extension Database {

    /// Search database for persons based on search criteria. The birthPartSets and deathPartSets are
    /// arrays of [part:Set<Key>] maps, one for each part in the criteria.
    public func searchPersons(_ criteria: SearchCriteria) -> [SearchResult] {
        var nameSet: Set<RecordKey> = []
        var birthDateSet: Set<RecordKey> = []
        var deathDateSet: Set<RecordKey> = []
        var birthPartSets: [String : Set<RecordKey>] = [:]
        var deathPartSets: [String : Set<RecordKey>] = [:]

        if let name = criteria.name {  // Get persons matching name.
            nameSet = Set(personKeys(forName: name))
        }
        if let range = criteria.birthYearRange {  // Get persons matching birth year range.
            birthDateSet = dateIndex.recordKeys(in: range, event: .birth)
        }
        if let range = criteria.deathYearRange {  // Get persons matching death year range.
            deathDateSet = dateIndex.recordKeys(in: range, event: .death)
        }
        if let place = criteria.birthPlace {  // Get persons matching birth place parts.
            birthPartSets = placeIndex.recordKeys(place: place, event: .birth)
        }
        if let place = criteria.deathPlace {  // Get persons matching death place parts.
            deathPartSets = placeIndex.recordKeys(place: place, event: .death)
        }
        // Create candidates structure.
        let candidateSets = CandidateSets(nameSet: nameSet, birthDateSet: birthDateSet,
                                          deathDateSet: deathDateSet, birthPartSets: birthPartSets,
                                          deathPartSets: deathPartSets)
        var results: SearchResults = [:]
        if !nameSet.isEmpty {  // If there are names do name based search.
            results = nameBasedSearch(candidateSets)
        } else {  // Otherwise do a date and place based search.
            results = datePlaceBasedSearch(candidateSets)
        }
        return results.values.sorted {  // Convert SearchResults to sorted [SearchResult].
            $0.compare(to: $1, in: recordIndex) == .orderedAscending
        }
    }
}

/// Do name-based search. Only persons matching name are returned.
private func nameBasedSearch(_ candidateSets: CandidateSets) -> SearchResults {

    var results: SearchResults = [:]
    let personSet = candidateSets.nameSet
    guard !personSet.isEmpty else { return [:] } // Should not happen.
    results.reserveCapacity(personSet.count)

    for key in personSet {  // Create search result for each person.
        results[key] = SearchResult(key: key, score: 0, reasons: ["name"])
    }
    for key in personSet.intersection(candidateSets.birthDateSet) {
        updateResult(&results, key, score: 40, reason: "birthDate")
    }
    for key in personSet.intersection(candidateSets.deathDateSet) {
        updateResult(&results, key, score: 40, reason: "deathDate")
    }
    for (_, keySet) in candidateSets.birthPartSets {
        for key in personSet.intersection(keySet) {
            updateResult(&results, key, score: 20, reason: "birthPlace")
        }
    }
    for (_, keySet) in candidateSets.deathPartSets {
        for key in personSet.intersection(keySet) {
            updateResult(&results, key, score: 20, reason: "deathPlace")
        }
    }
    return results
}

/// Get search results if criteria does not include name.
private func datePlaceBasedSearch(_ candidateSets: CandidateSets) -> SearchResults {
    var results: SearchResults = [:] // [RecordKey : SearchResult]
    results.reserveCapacity(250)  // Do better job with capacity.

    // Create search result for every person found in the indexes.
    candidateSets.birthDateSet.forEach { key in updateResult(&results, key, score: 20, reason: "birthDate") }
    candidateSets.deathDateSet.forEach { key in updateResult(&results, key, score: 20, reason: "deathDate") }
    for (_, keySet) in candidateSets.birthPartSets {
        for key in keySet {
            updateResult(&results, key, score: 20, reason: "birthPlace")
        }
    }
    for (_, keySet) in candidateSets.deathPartSets {
        for key in keySet {
            updateResult(&results, key, score: 20, reason: "deathPlace")
        }
    }
    return results
}
