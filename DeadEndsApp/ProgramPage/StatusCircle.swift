//
//  StatusCircle.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 30 May 2026.
//  Last changed on 18 June 2026.
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

/// Combined button and status circle.
struct StatusButton: View {

    let title: String
    let state: StatusState
    let disabled: Bool
    let action: () -> Void

    /// Create a new status button.
    init(_ title: String, state: StatusState, disabled: Bool = false,
        action: @escaping () -> Void) {
        self.title = title
        self.state = state
        self.disabled = disabled
        self.action = action
    }

    /// Status button view.
    var body: some View {
        HStack(spacing: 6) {
            Button(title, action: action)
                .disabled(disabled)
            StatusCircle(state: state)
        }
    }
}
