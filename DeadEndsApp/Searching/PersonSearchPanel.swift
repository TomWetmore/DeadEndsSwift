//
//  PersonSearchPanel.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 9 February 2026.
//  Last changed on 14 February 2026.
//

import SwiftUI
import DeadEndsLib

// MARK: - SearchPanel


struct PersonSearchPanel: View {

    @Environment(\.dismiss) private var dismiss

    // Caller owns criteria for persistence between openings.
    @Binding var criteria: SearchCriteria

    /// Run search and return person record keys.
    let onSearch: (SearchCriteria) -> [RecordKey]

    /// Called when user taps a result.
    let onSelect: (RecordKey) -> Void

    // Local draft fields (UI-friendly)
    @State private var draft: SearchCriteria = .init()
    @State private var birthFromText: String = ""
    @State private var birthToText: String = ""
    @State private var deathFromText: String = ""
    @State private var deathToText: String = ""
    @State private var birthPlaceText: String = ""
    @State private var deathPlaceText: String = ""
    //@State private var placeText: String = ""   // Canonicalize later.

    @State private var results: [RecordKey] = []
    @State private var lastError: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                criteriaSection
                yearsSection
                placeSection

                if let lastError {
                    Section {
                        Text(lastError)
                            .foregroundStyle(.red)
                    }
                }

                resultsSection
            }
            .navigationTitle("Search")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Search") { runSearch() }
                        .keyboardShortcut(.defaultAction)
                }
            }
            .onAppear {
                loadFromBinding()
            }
        }
    }

    // MARK: - Sections

    private var criteriaSection: some View {
        Section("Name") {
            TextField("Name contains…", text: Binding(
                get: { draft.name ?? "" },
                set: { draft.name = $0.isEmpty ? nil : $0 }
            ))
            .autocorrectionDisabled()
        }
    }

    private var yearsSection: some View {
        Section("Years") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Birth year range").font(.subheadline)
                HStack {
                    TextField("From", text: $birthFromText)
                        .frame(maxWidth: 90)
                    Text("to")
                    TextField("To", text: $birthToText)
                        .frame(maxWidth: 90)
                    Spacer()
                    Button("Clear") {
                        birthFromText = ""
                        birthToText = ""
                        draft.birthYearRange = nil
                    }
                    .buttonStyle(.borderless)
                }

                Text("Death year range").font(.subheadline)
                HStack {
                    TextField("From", text: $deathFromText)
                        .frame(maxWidth: 90)
                    Text("to")
                    TextField("To", text: $deathToText)
                        .frame(maxWidth: 90)
                    Spacer()
                    Button("Clear") {
                        deathFromText = ""
                        deathToText = ""
                        draft.deathYearRange = nil
                    }
                    .buttonStyle(.borderless)
                }

                Button("Clear All Year Filters") {
                    birthFromText = ""
                    birthToText = ""
                    deathFromText = ""
                    deathToText = ""
                    draft.birthYearRange = nil
                    draft.deathYearRange = nil
                }
            }
        }
    }

//    private var placeSection: some View {
//        Section("Place") {
//            TextField("Place contains…", text: $placeText)
//                .autocorrectionDisabled()
//
//            // For now we *don’t* canonicalize; we just stash something simple.
//            // Later: split into canonical parts with your existing placeParts(place) logic.
//            Button("Use this place text") {
//                let parts = placeText
//                    .split(separator: ",")
//                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
//                    .filter { !$0.isEmpty }
//                draft.placeParts = parts.isEmpty ? nil : parts
//            }
//            .buttonStyle(.borderless)
//
//            if let comps = draft.placeParts, !comps.isEmpty {
//                Text("Parts: " + comps.joined(separator: " • "))
//                    .font(.footnote)
//                    .foregroundStyle(.secondary)
//            }
//
//            Button("Clear Place Filter") {
//                placeText = ""
//                draft.placeParts = nil
//            }
//            .buttonStyle(.borderless)
//        }
//    }

    private var placeSection: some View {
        Section("Places") {
            TextField("Birth place…", text: $birthPlaceText)
                .autocorrectionDisabled()

            TextField("Death place…", text: $deathPlaceText)
                .autocorrectionDisabled()

            Button("Clear Place Filters") {
                birthPlaceText = ""
                deathPlaceText = ""
                draft.birthPlace = nil
                draft.deathPlace = nil
            }
            .buttonStyle(.borderless)
        }
    }

    private var resultsSection: some View {
        Section("Results") {
            if results.isEmpty {
                Text("No results yet.")
                    .foregroundStyle(.secondary)
            } else {
                List(results, id: \.self) { key in
                    Button {
                        onSelect(key)
                        dismiss()
                    } label: {
                        Text(key) // Replace with display name if you want
                    }
                }
                .frame(minHeight: 200)
            }

            HStack {
                Button("Clear Results") {
                    results = []
                }
                .buttonStyle(.borderless)

                Spacer()

                Button("Clear All") {
                    clearAll()
                }
                .buttonStyle(.borderless)
            }
        }
    }

    // MARK: - Actions

    private func loadFromBinding() {
        draft = criteria

        if let r = criteria.birthYearRange {
            birthFromText = String(r.lowerBound)
            birthToText = String(r.upperBound)
        }
        if let r = criteria.deathYearRange {
            deathFromText = String(r.lowerBound)
            deathToText = String(r.upperBound)
        }
        birthPlaceText = criteria.birthPlace ?? ""
        deathPlaceText = criteria.deathPlace ?? ""
    }

    private func runSearch() {
        lastError = nil

        // Parse year ranges from text fields (optional)
        if let range = parseRange(from: birthFromText, to: birthToText) {
            draft.birthYearRange = range
        } else if !birthFromText.isEmpty || !birthToText.isEmpty {
            lastError = "Birth year range is not valid."
            return
        } else {
            draft.birthYearRange = nil
        }

        if let range = parseRange(from: deathFromText, to: deathToText) {
            draft.deathYearRange = range
        } else if !deathFromText.isEmpty || !deathToText.isEmpty {
            lastError = "Death year range is not valid."
            return
        } else {
            draft.deathYearRange = nil
        }

        // If user typed place text but didn’t hit “Use this place text”, do a simple default.
        let bp = birthPlaceText.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.birthPlace = bp.isEmpty ? nil : bp

        let dp = deathPlaceText.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.deathPlace = dp.isEmpty ? nil : dp
        criteria = draft
        results = onSearch(criteria)
    }

    /// Parse two strings that should be years and return the closed range of those years.
    private func parseRange(from: String, to: String) -> ClosedRange<Year>? {
        guard let lo = Int(from.trimmingCharacters(in: .whitespacesAndNewlines)),
              let hi = Int(to.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }
        guard lo <= hi else { return nil }
        return lo...hi
    }

    private func clearAll() {
        draft = .init()
        criteria = draft
        birthFromText = ""
        birthToText = ""
        deathFromText = ""
        deathToText = ""
        birthPlaceText = ""
        deathPlaceText = ""
        results = []
        lastError = nil
    }
}
