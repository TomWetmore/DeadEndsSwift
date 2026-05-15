//
//  PickerSupport.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 May 2026.
//  Last changed on 15 May 2026.
//

import SwiftUI
import DeadEndsLib

struct PersonChoiceRow: View {
    let person: Person

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(person.displayName())
                .font(.title3)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subtitle: String {
        let birth = person.birthEvent?.summary
        let death = person.deathEvent?.summary

        switch (birth, death) {
        case let (b?, d?): return "born \(b) — died \(d)   \(person.key)"
        case let (b?, nil): return "born \(b)   \(person.key)"
        case let (nil, d?): return "died \(d)   \(person.key)"
        default: return person.key
        }
    }
}
