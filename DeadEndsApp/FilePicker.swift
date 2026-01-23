//
//  FilePicker.swift
//  DisplayPerson
//
//  Created by Thomas Wetmore on 6/23/25.
//. Last changed on 19 January 2026.
//

import SwiftUI
import Foundation
import AppKit

func chooseGedcomFile() -> String? {
    let panel = NSOpenPanel()
    panel.allowedFileTypes = ["ged"]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.title = "Select GEDCOM File"

    return panel.runModal() == .OK ? panel.url?.path : nil
}

struct FileChooserButton: View {
    let label: String
    let onSelect: (String) -> Void

    var body: some View {
        Button(label) {
            if let path = chooseGedcomFile() {
                onSelect(path)
            }
        }
    }
}
