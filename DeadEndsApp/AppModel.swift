//
//  AppModel.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 22 June 2025.
//  Last changed on 16 November 2025.
//

import SwiftUI
import DeadEndsLib

@MainActor
@Observable
class AppModel: ObservableObject {
    var database: Database? // DeadEnds Database.
    var path = NavigationPath() // Navigation stack.
    var status: String? // Status text shown on major views.
}

