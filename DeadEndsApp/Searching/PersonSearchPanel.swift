//
//  PersonSearchPanel.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 9 February 2026.
//  Last changed on 26 June 2026.
//

import SwiftUI
import DeadEndsLib

/// Person search panel using names and vitals dates and places.
struct PersonSearchPanel: View {
    
    @Environment(\.dismiss) private var dismiss
    @Binding var criteria: SearchCriteria // Caller owned search criteria.
    let onSearch: (SearchCriteria) -> [SearchResult] // Search and return results.
    let onSelect: (RecordKey) -> Void // Run when user taps a result row.
    let resultDescription: (SearchResult) -> String

    @State private var draft: SearchCriteria = .init()  // Search criteria fields.
    @State private var birthFromText: String = ""
    @State private var birthToText: String = ""
    @State private var deathFromText: String = ""
    @State private var deathToText: String = ""
    @State private var birthPlaceText: String = ""
    @State private var deathPlaceText: String = ""

    @State private var results: [SearchResult] = []
    @State private var lastError: String? = nil

    /// The person search panel view.
    var body: some View {

        NavigationStack {
            VStack(spacing: 0) {

                Form {
                    nameSection
                    yearsSection
                    placeSection

                    if let lastError {
                        Section {
                            Text(lastError).foregroundStyle(.red)
                        }
                    }
                }
                Divider()

                resultsSection
            }
            .navigationTitle("Search")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                // Make search the default button. Then pressing return anywhere
                // in the sheet activates this button.
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

    /// Name section.
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

    /// Years section.
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

    /// Place section.
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

    /// Results section.
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Results")
                .font(.headline)

            if results.isEmpty {
                Text("No results yet.")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(results) { result in
                            Button {
                                onSelect(result.key)
                                dismiss()
                            } label: {
                                resultRow(result)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding()
    }

    /// Show a search result row.
    private func resultRow(_ result: SearchResult) -> some View {

        VStack(alignment: .leading, spacing: 3) {
            Text(resultDescription(result))
            Text(result.extraDebugDescription()) // TODO: Remove after development.
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }

    
    /// Load from binding.
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

    /// Run search. Called when the user clicks the search button in the panel's
    /// tool bar or hits the return key. It builds a criterion from the text fields
    /// and then calls the panel's onSearch function to get the results.
    private func runSearch() {

        lastError = nil
        // Get the year ranges if there.
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

        // Get the place strings if there.
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

    /// Clear the search fields, results and lastError.
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
