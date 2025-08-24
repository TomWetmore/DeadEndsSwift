//
//  GedcomName.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 1 January 2025.
//  Last changed on 21 August 2025.
//

import Foundation

// A structured representation of a GEDCOM name.
public struct GedcomName: Comparable {
    var givenNames: [String]
    var surname: String?
    var surnameIndex: Int

    // MARK: - Initializers

    /// Initializes from pre-separated components
    init(givenNames: [String], surname: String?, surnameIndex: Int) {
        self.givenNames = givenNames
        self.surname = surname
        self.surnameIndex = surnameIndex
    }

    /// Parses a raw GEDCOM name (slashes around surname)
    public init(_ raw: String) {
        if let start = raw.firstIndex(of: "/") {
            let end = raw[start...].dropFirst().firstIndex(of: "/") ?? raw.endIndex

            let surname: String
            if raw.index(after: start) <= end {
                surname = String(raw[raw.index(after: start)..<end]).trimmingCharacters(in: .whitespaces)
            } else {
                surname = ""
            }

            let givenBefore = raw[..<start].trimmingCharacters(in: .whitespaces)
            let givenAfter = (end < raw.endIndex)
                ? raw[raw.index(after: end)...].trimmingCharacters(in: .whitespaces)
                : ""

            let beforeArray = givenBefore.split(separator: " ").map(String.init)
            let afterArray = givenAfter.split(separator: " ").map(String.init)
            let givenNames = beforeArray + afterArray
            let surnameIndex = beforeArray.count

            self.init(givenNames: givenNames, surname: surname, surnameIndex: surnameIndex)
        } else {
            // No slashes: treat entire string as given names
            let givenNames = raw.split(separator: " ").map(String.init)
            self.init(givenNames: givenNames, surname: nil, surnameIndex: -1)
        }
    }

    // MARK: - Derived properties

    /// The first initial (uppercased) of the first given name, or nil.
    var firstInitial: Character? {
        return givenNames.first?.first(where: \.isLetter)?.uppercased().first
    }

    /// Lowercased given name pieces (squeezed)
    var squeezedGivenNames: [String] {
        return givenNames.map { $0.lowercased() }
    }

    /// A string form of the name (with slash-surrounded surname if present)
    var stringValue: String {
        let surnamePart = surname.map { "/\($0)/" } ?? ""
        var pieces = givenNames
        if surnameIndex >= 0 && surnameIndex < givenNames.count {
            pieces.insert(surnamePart, at: surnameIndex)
        } else {
            pieces.append(surnamePart)
        }
        return pieces.joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Comparison

    /// Compare two GedcomNames according to surname, initial, and given name order
    func compare(to other: GedcomName) -> ComparisonResult {
        let s1 = surname?.lowercased() ?? ""
        let s2 = other.surname?.lowercased() ?? ""
        let r1 = s1.compare(s2)
        if r1 != .orderedSame {
            return r1
        }

        switch (firstInitial, other.firstInitial) {
        case let (a?, b?) where a != b:
            return a < b ? .orderedAscending : .orderedDescending
        case (.some, .none): return .orderedAscending
        case (.none, .some): return .orderedDescending
        default: break
        }

        for (a, b) in zip(squeezedGivenNames, other.squeezedGivenNames) {
            let cmp = a.compare(b)
            if cmp != .orderedSame { return cmp }
        }

        // If one has more remaining
        if squeezedGivenNames.count < other.squeezedGivenNames.count { return .orderedAscending }
        if squeezedGivenNames.count > other.squeezedGivenNames.count { return .orderedDescending }

        return .orderedSame
    }

    public static func < (lhs: GedcomName, rhs: GedcomName) -> Bool {
        lhs.compare(to: rhs) == .orderedAscending
    }
}

extension GedcomNode {
    public var gedcomName: GedcomName? {
        self.child(withTag: "NAME")?.value.map(GedcomName.init)
    }
}

extension GedcomNode {
    /// Extracts and formats the person's name for display.
    public var displayName: String {
        if let raw = self.child(withTag: "NAME")?.value {
            // Strip slashes from surname for display
            return raw.replacingOccurrences(of: "/", with: "").trimmingCharacters(in: .whitespaces)
        }
        return "(no name)"
    }
}


// displayName returns the name of a Person ready for display.
extension GedcomNode {
    /// Formats GEDCOM NAME as "Given Surname Suffix".
    /// Ensures a space before surname (if given exists) and after surname (if suffix exists).
    public func displayName(uppercaseSurname: Bool = false) -> String {
        guard var raw = self.child(withTag: "NAME")?.value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return "(no name)" }

        // Squeeze internal whitespace to single spaces.
        func squeeze(_ s: String) -> String {
            s.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        }

        // Find first/last slash; surname is between them.
        guard let first = raw.firstIndex(of: "/"),
              let last  = raw.lastIndex(of: "/"),
              first < last else {
            // No valid slashes: drop slashes, squeeze spaces.
            return squeeze(raw.replacingOccurrences(of: "/", with: " "))
        }

        let given   = squeeze(String(raw[..<first]))
        let surname = squeeze(String(raw[raw.index(after: first)..<last]))
        let suffix  = squeeze(String(raw[raw.index(after: last)...]))

        let finalSurname = uppercaseSurname ? surname.uppercased() : surname

        switch (given.isEmpty, finalSurname.isEmpty, suffix.isEmpty) {
        case (true,  false, true ): return finalSurname
        case (true,  false, false): return "\(finalSurname) \(suffix)"
        case (false, false, true ): return "\(given) \(finalSurname)"
        case (false, false, false): return "\(given) \(finalSurname) \(suffix)"
        case (_,     true,  _     ): // no surname—just show what we have
            return [given, suffix].filter { !$0.isEmpty }.joined(separator: " ")
        }
    }
}

