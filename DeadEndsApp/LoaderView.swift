//
//  LoaderView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 24 June 2025.
//  Last changed on 18 July 2025.
//

import SwiftUI
import AppKit
import DeadEndsLib

//
//  LoaderView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 24 June 2025.
//  Last changed on 18 July 2025.
//

import SwiftUI
import AppKit
import DeadEndsLib

/// A view that prompts the user to select a GEDCOM file and loads it into the DeadEnds database.
struct LoaderView: View {
    /// The shared application model used to store and update the current database.
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack {
            Text("Please choose a Gedcom file to load into a DeadEnds database.")
                .font(.title)

            Button("Open Gedcom File") {
                if let path = openGedcomPanel() {
                    var log = ErrorLog()
                    if let db = loadDatabase(from: path, errlog: &log) {
                        model.database = db
                    } else {
                        print("Failed to load GEDCOM:\n\(log)")
                    }
                }
            }
            .font(.body)
        }
        .padding()
    }

    /// Presents an open file dialog for selecting a `.ged` file.
    ///
    /// - Returns: The path to the selected GEDCOM file, or `nil` if the user cancels the panel.
    func openGedcomPanel() -> String? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "ged")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        return panel.runModal() == .OK ? panel.url?.path : nil
    }
}
