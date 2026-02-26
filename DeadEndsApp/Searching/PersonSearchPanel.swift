//
//  PersonSearchPanel.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 9 February 2026.
//  Last changed on 25 February 2026.
//

import SwiftUI
import DeadEndsLib

/// Person search panel using names and vitals dates and places.
struct PersonSearchPanel: View {

    @Environment(\.dismiss) private var dismiss
    @Binding var criteria: SearchCriteria  // Caller owns search criteria.
    let onSearch: (SearchCriteria) -> [RecordKey]  // Run search and return record keys.
    let onSelect: (RecordKey) -> Void  // Run when user taps a result.

    @State private var draft: SearchCriteria = .init()  // Search criteria fields.
    @State private var birthFromText: String = ""
    @State private var birthToText: String = ""
    @State private var deathFromText: String = ""
    @State private var deathToText: String = ""
    @State private var birthPlaceText: String = ""
    @State private var deathPlaceText: String = ""

    @State private var results: [RecordKey] = []
    @State private var lastError: String? = nil

    /// Render person search panel.
    var body: some View {
        NavigationStack {
            Form {
                //criteriaSection
                nameSection  // Drop in from ChatGPT.
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

    private var nameSection: some View {
            Section("Name") {
                TextField("", text: Binding(
                    get: { draft.name ?? "" },
                    set: { draft.name = $0.isEmpty ? nil : $0 }
                ),
                          prompt: Text("Givens/Surname"))
                .autocorrectionDisabled()
            }
        }



    private var yearsSection: some View {
        Section("Years") {
            LabeledContent("Birth") {
                HStack(spacing: 12) {
                    TextField("From", text: $birthFromText).frame(width: 80)
                    TextField("To", text: $birthToText).frame(width: 80)
                }
            }
            LabeledContent("Death") {
                HStack(spacing: 12) {
                    TextField("From", text: $deathFromText).frame(width: 80)
                    TextField("To", text: $deathToText).frame(width: 80)
                }
            }
        }
    }

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

//            HStack {
//                Button("Clear Results") {
//                    results = []
//                }
//                .buttonStyle(.borderless)
//
//                Spacer()
//
//                Button("Clear All") {
//                    clearAll()
//                }
//                .buttonStyle(.borderless)
//            }
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
