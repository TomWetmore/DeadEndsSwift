//
//  WrappedModel.swift
//  DeadEndsProgApp
//
//  Created by Thomas Wetmore on 28 May 2026.
//  Last changed on 28 May 2026.
//

import Foundation
import DeadEndsLib

@Observable
final class WrappedModel {
    
    var database: Database?
    var programModel = ProgramModel()
}
