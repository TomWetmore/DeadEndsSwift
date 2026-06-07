//
//  StatusLight.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 30 May 2026.
//  Last changed on 3 June 2026.
//

import SwiftUI

/// Small colored circle that shows the status of an operation.
struct StatusCircle: View {

    let state: StatusState

    var body: some View {
        Group {
            switch state {
            case .initial:
                Circle().stroke(color, lineWidth: 1)
            default:
                Circle().fill(color)
            }
        }
        .frame(width: 11, height: 11)
    }

    private var color: Color {
        switch state {
        case .initial: .secondary
        case .working: .orange
        case .success: .green
        case .failure: .red
        }
    }
}

enum StatusState {
    case initial
    case working
    case success
    case failure
}
