//
//  Search.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 11/26/25.
//

import Foundation

struct SearchCriteria {
    var name: String?
    var birthYearRange: ClosedRange<Year>?
    var deathYearRange: ClosedRange<Year>?
    var placeComponents: [String]?  // canonical parts
    var personKeysToLimit: Set<RecordKey>?  // for narrowing

    // Later:
    var fuzzy: Bool = false
    var weightName = 1.0
    var weightPlace = 1.0
}

func search(_ criteria: SearchCriteria) -> [RecordKey] {
    return []
}

//func alpha(_ criteria: SearchCriteria, database: Database) -> [RecordKey] {
//    let yearSets = yearsInRange.map { database.dateIndex.keys(year: $0, event: .birth) ?? [] }
//    let birthMatches = Set.intersection(of: yearSets)
//}

