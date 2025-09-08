//
//  AppModel.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 22 June 2025.
//  Last changed on 29 August 2025.
//

import SwiftUI
import DeadEndsLib

@MainActor
class AppModel: ObservableObject {
    @Published var database: Database? // DeadEnds Database.
    @Published var path = NavigationPath() // Navigation stack.
    @Published var status: String? // Status text shown on major views.
}

