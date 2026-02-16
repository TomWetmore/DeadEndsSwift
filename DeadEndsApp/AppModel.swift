//
//  AppModel.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 22 June 2025.
//  Last changed on 15 February 2026.
//

import SwiftUI
import DeadEndsLib

/// Application model, including the database, navigation path and status string. Injected
/// into the environment in DeadEndsApp so available throughout the view hiearchy.
@MainActor
@Observable
class AppModel: ObservableObject {

    var database: Database? // DeadEnds Database.
    var path = NavigationPath() // Navigation stack.
    var status: String? // Status text shown on some pages.
}


extension AppModel {

    /// Search persons. Pass along to the database.
    func searchPersons(_ criteria: SearchCriteria) -> [SearchResult] {
        guard let db = database else { return [] }
        return db.searchPersons(criteria)
    }
}

