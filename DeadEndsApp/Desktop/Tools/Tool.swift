//
//  Tool.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 3 November 2025.
//  Last changed on 3 November 2025.
//

import Foundation
import DeadEndsLib

enum ToolKind: Identifiable, Hashable {
    case mergePersons(personA: Person, personB: Person)
    // later: createFamily, attachEvidence, etc.
    var id: String { UUID().uuidString }
}

final class ToolModel: ObservableObject, Identifiable {
    let kind: ToolKind
    @Published var position: CGPoint = .zero   // if you want draggable tools later
    init(kind: ToolKind) { self.kind = kind }
}
