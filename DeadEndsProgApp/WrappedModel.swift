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
    var databaseState: DatabaseState = .empty

    @MainActor
    func loadDatabase() {

        guard let path = openGedcomFilePanel() else { return }
        var log = ErrorLog()
        databaseState = .loading
        if let database = DeadEndsLib.loadDatabase(from: path, errlog: &log) {
            self.database = database
            databaseState = .success
        } else {
            databaseState = .failure
            print("Failed to load Gedcom file:\n\(log)")
        }
    }

    enum DatabaseState {
        case empty
        case loading
        case success
        case failure
    }
}
