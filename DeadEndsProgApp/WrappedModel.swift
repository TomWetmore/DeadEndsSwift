//
//  WrappedModel.swift
//  DeadEndsProgApp
//
//  Created by Thomas Wetmore on 28 May 2026.
//  Last changed on 29 May 2026.
//

import Foundation
import DeadEndsLib

@Observable
final class WrappedModel {
    
    var database: Database?
    var programModel = ProgramModel()

    @MainActor
    func loadDatabase() {

        guard let path = openGedcomFilePanel() else { return }
        var log = ErrorLog()
        if let database = DeadEndsLib.loadDatabase(from: path, errlog: &log) {
            self.database = database
        } else {
            print("Failed to load Gedcom file:\n\(log)")
        }
    }
}
