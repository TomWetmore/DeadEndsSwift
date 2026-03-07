//
//  LoaderView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 24 June 2025.
//  Last changed on 6 March 2026.
//

import SwiftUI
import DeadEndsLib

/// View that prompts user to select a Gedcom file to load into a database.
struct LoadGedcomFileView: View {
    @EnvironmentObject var model: AppModel

    /// Render the loader view.
    var body: some View {
        VStack {
            Text("Choose a Gedcom file to load into the database.").font(.title)
            Button("Open Gedcom File") {
                if let path = openGedcomFilePanel() {
                    var log = ErrorLog()
                    if let database = loadDatabase(from: path, errlog: &log) {
                        model.database = database
                    } else {
                        print("Failed to load Gedcom file:\n\(log)")
                    }
                }
            }.font(.body)
        }.padding()
    }

    /// Open file dialog for choosing a Gedcom file.
    func openGedcomFilePanel() -> String? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "ged")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        return panel.runModal() == .OK ? panel.url?.path : nil
    }
}
