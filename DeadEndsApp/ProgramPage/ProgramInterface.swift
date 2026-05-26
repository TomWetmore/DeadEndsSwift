//
//  ProgramOutput.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 24 May 2026.
//  Last changed on 24 May 2026.
//

import Foundation
import DeadEndsLib

/// Request that causes the program page to open a user interaction sheet.
enum ProgramRequest: Identifiable {
    case getPerson(GetPersonRequest)
    case getInteger(GetIntegerRequest)
    case getString(GetStringRequest)

    var id: UUID {
        switch self {
        case .getPerson(let request): return request.id
        case .getInteger(let request): return request.id
        case .getString(let request): return request.id
        }
    }
}

struct GetPersonRequest: Identifiable {
    let id = UUID()
    let prompt: String
}

struct GetIntegerRequest: Identifiable {
    let id = UUID()
    let prompt: String
}

struct GetStringRequest: Identifiable {
    let id = UUID()
    let prompt: String
}

/// Conformance that buffers DeadEnds program output to a string while the
/// program is running. Output is periodically sent to the text view.
final class BufferedOutput: ProgramOutput {

    private(set) var text = ""
    let publish: @MainActor (String) -> Void

    init(publish: @escaping @MainActor (String) -> Void) {
        self.publish = publish
    }

    /// Append a string to the buffer.
    func write(_ s: String) {
        text += s
    }

    /// Flush the string.
    @MainActor func flush() async {
        let current = text
        await MainActor.run {
            publish(displayableOutput(current))
        }
    }

    func clear() {
        text = ""
    }
}

@Observable
@MainActor
final class UIProgramOutput {
    var text: String = ""

    func clear() {
        text = ""
    }
}

/// Mechanism to limit the size of the output view.
private let maxOutputChars = 100_000

func displayableOutput(_ text: String) -> String {

    if text.count <= maxOutputChars {
        return text
    }
    return String(text.prefix(maxOutputChars))
        + "\n\n[output truncated: \(text.count) characters total]"
}
