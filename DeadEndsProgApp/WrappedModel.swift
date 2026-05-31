//
//  WrappedModel.swift
//  DeadEndsProgApp
//
//  Created by Thomas Wetmore on 28 May 2026.
//  Last changed on 31 May 2026.
//

import Foundation
import DeadEndsLib

@Observable
final class WrappedModel {
    
    var database: Database?
    var programModel = ProgramModel()
    var databaseState: StatusState = .initial

    @MainActor
    func loadDatabase() {

        databaseState = .working
        guard let path = openGedcomFilePanel() else {
            databaseState = .failure
            return
        }
        var log = ErrorLog()
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
