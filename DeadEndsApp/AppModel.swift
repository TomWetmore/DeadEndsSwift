//
//  AppModel.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 22 June 2025.
//  Last changed on 2 July 2025.
//

import Foundation
import DeadEndsLib
import SwiftUI

@MainActor
class AppModel: ObservableObject {
    @Published var database: Database? // DeadEnds Database read from Gedcom file.
    @Published var path = NavigationPath() // Navigation stack.
    @Published var status: String? // Status text show on major views.
}

