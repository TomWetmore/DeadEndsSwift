//
//  iPadRunnerModel.swift
//  DeadEndsIPad
//
//  Created by Thomas Wetmore on 13 June 2026.
//  Last changed on 13 June 2026.
//

import SwiftUI
import DeadEndsLib
import UniformTypeIdentifiers

@MainActor
@Observable
final class IPadRunnerModel {

    var database: Database?
    var programModel = ProgramModel()

    var showingDatabaseImporter = false
    var showingProgramImporter = false

    var databaseState: StatusState = .initial

    func loadProgram(from url: URL) {
        do {
            let ok = url.startAccessingSecurityScopedResource()
            defer {
                if ok { url.stopAccessingSecurityScopedResource() }
            }

            programModel.source = try String(contentsOf: url, encoding: .utf8)
            programModel.programName = url.lastPathComponent
            programModel.sourceWasEdited()
            programModel.openState = .success
        } catch {
            programModel.diagnostics = [
                Diagnostic(message: "Could not open program: \(error.localizedDescription)", line: nil)
            ]
            programModel.openState = .failure
        }
    }

    func loadDatabase(from url: URL) {
        databaseState = .working

        let ok = url.startAccessingSecurityScopedResource()
        defer {
            if ok { url.stopAccessingSecurityScopedResource() }
        }

        var log = ErrorLog()

        if let database = DeadEndsLib.loadDatabase(from: url.path, errlog: &log) {
            self.database = database
            databaseState = .success
        } else {
            databaseState = .failure
            print("Failed to load GEDCOM file:\n\(log)")
        }
    }
}
