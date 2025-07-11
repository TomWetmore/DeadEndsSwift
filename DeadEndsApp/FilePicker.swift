//
//  FilePicker.swift
//  DisplayPerson
//
//  Created by Thomas Wetmore on 6/23/25.
//

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

import SwiftUI

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
