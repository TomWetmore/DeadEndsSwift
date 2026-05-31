//
//  StatusLight.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 30 May 2026.
//  Last changed on 30 May 2026.
//

import SwiftUI

/// Small colored circle for showing state or status.
struct StatusLight: View {

    let state: StatusState

    let initialHelp: String
    let successHelp: String
    let workingHelp: String
    let failureHelp: String

    var body: some View {

        Circle()
            .fill(color)
            .frame(width: 11, height: 11)
            .help(help)
    }

    private var color: Color {
        switch state {
        case .initial: .gray
        case .working: .orange
        case .success: .green
        case .failure: .red
        }
    }

    private var help: String {
        switch state {
        case .initial: initialHelp
        case .working: workingHelp
        case .success: successHelp
        case .failure: failureHelp
        }
    }
}

enum StatusState {
    case initial
    case working
    case success
    case failure
}
