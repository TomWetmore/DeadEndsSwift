//
//  LoaderView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 24 June 2025.
//  Last changed on 5 July 2025.
//

import SwiftUI
import AppKit
import DeadEndsLib

struct LoaderView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack {
            Text("Please load a GEDCOM file")
            Button("Open GEDCOM") {
                if let path = openGedcomPanel() {
                    var log = ErrorLog()
                    if let db = getDatabaseFromPath(path, errlog: &log) {
                        model.database = db
                    } else {
                        print("Failed to load GEDCOM:\n\(log)")
                    }
                }
            }
        }
        .padding()
    }

    func openGedcomPanel() -> String? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "ged")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        return panel.runModal() == .OK ? panel.url?.path : nil
    }
}
