//
//  AppModel.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 22 June 2025.
//  Last changed on 24 February 2026.
//

import SwiftUI
import DeadEndsLib

/// Application model. Added to the view environment by the root view.
@MainActor
@Observable
class AppModel: ObservableObject {
    var database: Database?
    var path = NavigationPath()
    var status: String?
}

extension AppModel {

    /// Search for persons matching criteria. Pass along to the database.
    func searchPersons(_ criteria: SearchCriteria) -> [SearchResult] {
        guard let database = database else { return [] }
        return database.searchPersons(criteria)
    }
}

