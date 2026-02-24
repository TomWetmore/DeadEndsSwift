//
//  LoaderView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 24 June 2025.
//  Last changed on 24 February 2026.
//

import SwiftUI
import DeadEndsLib

/// View that prompts user to select a Gedcom file which is then loaded into a DeadEnds Database.
struct LoaderView: View {

    @EnvironmentObject var model: AppModel  // Includes database.

    /// Body property for LoaderView.
    var body: some View {

        VStack {
            Text("Please choose a Gedcom file to load into a DeadEnds database.").font(.title)
            Button("Open Gedcom File") {
                if let path = openGedcomPanel() {
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
    func openGedcomPanel() -> String? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "ged")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        return panel.runModal() == .OK ? panel.url?.path : nil
    }
}
