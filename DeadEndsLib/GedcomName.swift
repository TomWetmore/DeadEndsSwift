//
//  GedcomName.swift
//  DeadEnds Library
//
//  Created by Thomas Wetmore on 1 January 2025.
//  Last changed on 16 February 2026.
//

import Foundation

/// Internal representation of a Gedcom 1 NAME value.
public struct GedcomName: Comparable, CustomStringConvertible {

    var parts: [String]  // Name parts.
    var surnameIndex: Int?  // Surname index if exists.

    /// Create Gedcom name from precomputed properties.
    private init(parts: [String], surnameIndex: Int?) {
        self.parts = parts
        if let s = surnameIndex, s >= 0, s < parts.count { self.surnameIndex = s }
        else { self.surnameIndex = nil }
    }

    /// Create Gedcom name from Gedcom-formatted name string.
    public init?(string: String) {
        guard let (parts, sindex) = parseGedcomName(value: string) else { return nil }
        self.init(parts: parts, surnameIndex: sindex)
    }

    /// Create Gedcom name from a 0 INDI or 1 NAME node.
    public init?(from node: GedcomNode) {
        let nameNode: GedcomNode? = (node.tag == "NAME") ? node : node.kid(withTag: "NAME")
        guard let value = nameNode?.val else { return nil }
        self.init(string: value)
    }

    /// Return description of Gedcom name showing struture.
    public var description: String {
        let parts = parts.enumerated()
            .map { idx, part in
                if idx == surnameIndex { return "[\(part)]" }  // Highlight surname.
                else { return part }
            }.joined(separator: " | ")
        return "GedcomName(parts: \(parts), surnameIndex: \(surnameIndex?.description ?? "nil"))"
    }

    /// Return length of Gedcom name.
    public var length: Int {
        return parts.count - 1 + parts.reduce(0) { $0 + $1.count }
    }

    /// Return display version of name; surname can be capitalized and/or appear first; name can be limited
    /// in length.
    public func displayName(upSurname: Bool = false, surnameFirst: Bool = false, limit: Int = 0) -> String {
        var work = self
        if upSurname { work.uppercaseSurname() }
        if limit > 0 { work.shortened(to: limit) }
        return work.format(surnameFirst: surnameFirst)
    }

    /// Format Gedcom name to string handling surname position.
    func format(surnameFirst: Bool) -> String {
        guard !parts.isEmpty else { return "" }
        if surnameFirst, let si = surnameIndex {  // Surname first.
            let surname = parts[si]
            let before = parts[..<si]
            let after = parts[(si + 1)..<parts.count]
            let rest = (before + after).joined(separator: " ")  // Join givens and suffixes.
            return rest.isEmpty ? surname : "\(surname), \(rest)"
        } else {
            return parts.joined(separator: " ")  // Normal surname placement format.
        }
    }

    /// Return first initial (uppercased) of the first given name.
    var firstInitial: Character? {
        return parts.first?.first(where: \.isLetter)?.uppercased().first
    }

    /// Return surname of Gedcom name if it exists.
    var surname: String? {
        if surnameIndex == nil { return nil }
        return parts[surnameIndex!]
    }

    /// Return array of name parts, excluding surname, in lower case.
    var lowercaseGivens: [String] {
        parts.enumerated()
            .compactMap { (i, part) in
                i == surnameIndex ? nil : part.lowercased()
            }
    }

    /// Uppercase the surname name part if exists.
    mutating func uppercaseSurname() {
        guard let i = surnameIndex else { return }
        parts[i] = parts[i].uppercased()
    }

    /// Convert given name to an initial with period in situ.
    mutating func initialiseGiven(at i: Int) {
        guard i >= 0 && i < parts.count && i != surnameIndex else { return }
        if let c = parts[i].first { parts[i] = "\(c)." }
    }

    /// Remove a given name part.
    mutating func removePart(at i: Int) {
        guard i >= 0 && i < parts.count && i != surnameIndex else { return }
        parts.remove(at: i)
        if let s = surnameIndex, i < s { surnameIndex = s - 1 }
        else if surnameIndex == i { surnameIndex = nil }
    }

    /// Remove suffixes (I think). I don't think this will be useful.
    mutating func dropSuffix(range: Range<Int>) {
        guard !range.isEmpty else { return }
        parts.removeSubrange(range)
        if let s = surnameIndex, range.lowerBound <= s {
            surnameIndex = s - min(s - range.lowerBound, range.count)
        }
    }

    /// Compare two Gedcom names by surname, initial, and given name order.
    func compare(to other: GedcomName) -> ComparisonResult {

        let s1 = surname?.lowercased() ?? ""  // Compare surnames.
        let s2 = other.surname?.lowercased() ?? ""
        let r1 = s1.compare(s2)
        if r1 != .orderedSame { return r1  }

        switch (firstInitial, other.firstInitial) {  // Compare first initials.
        case let (a?, b?) where a != b:
            return a < b ? .orderedAscending : .orderedDescending
        case (.some, .none): return .orderedAscending
        case (.none, .some): return .orderedDescending
        default: break
        }
        for (a, b) in zip(lowercaseGivens, other.lowercaseGivens) {  // Need big guns.
            let cmp = a.compare(b)
            if cmp != .orderedSame { return cmp }
        }
        if lowercaseGivens.count < other.lowercaseGivens.count { return .orderedAscending }
        if lowercaseGivens.count > other.lowercaseGivens.count { return .orderedDescending }

        return .orderedSame
    }

    /// Compare two Gedcom names for Comparable protocol.
    public static func < (lhs: GedcomName, rhs: GedcomName) -> Bool {
        lhs.compare(to: rhs) == .orderedAscending
    }
}

/// Parse Gedcom name string into parts and surname index.
private func parseGedcomName(value: String) -> (parts: [String], surnameIndex: Int?)? {

    if value.isEmpty { return nil }
    func squeeze(_ s: String) -> String {   // Squeeze whitespace to single spaces.
        s.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ") }
    let val = squeeze(value)
    let slashIdxs = val.indices.filter { val[$0] == "/" }  // Get indexes of slashes.

    func tokens(_ s: String) -> [String] {  // Split string into tokens.
        s.isEmpty ? [] : s.split(separator: " ").map(String.init)
    }

    switch slashIdxs.count {
    case 0:
        let givens = tokens(value)  // All givens.
        return (givens, nil)
    case 1:
        let first = slashIdxs[0]  // Surname from slash to end.
        let givenStr  = String(value[..<first]).trimmingCharacters(in: .whitespaces)
        let surnameStr = String(value[value.index(after: first)...]).trimmingCharacters(in: .whitespaces)
        let given = tokens(givenStr)
        let surname = squeeze(surnameStr.replacingOccurrences(of: "/", with: " "))
        var parts = given
        var sIndex: Int? = nil
        if !surname.isEmpty {
            sIndex = parts.count
            parts.append(surname)
        }
        return (parts, sIndex)

    default:
        let first = slashIdxs.first!   // First slash opens, lasr slash closes.
        let last  = slashIdxs.last!
        if first >= last {
            // Fallback
            return (tokens(value), nil)
        }
        let givenStr   = String(value[..<first]).trimmingCharacters(in: .whitespaces)
        var surnameStr = String(value[value.index(after: first)..<last]).trimmingCharacters(in: .whitespaces)
        surnameStr = squeeze(surnameStr.replacingOccurrences(of: "/", with: " "))
        let suffixStr  = String(value[value.index(after: last)...]).trimmingCharacters(in: .whitespaces)

        let given  = tokens(givenStr)
        let suffix = tokens(suffixStr)

        var parts = given
        var sIndex: Int? = nil
        if !surnameStr.isEmpty {
            sIndex = parts.count
            parts.append(surnameStr)
        }
        parts.append(contentsOf: suffix)
        return (parts, sIndex)
    }
}

// Methods for shortening Gedcom names.
extension GedcomName {

    /// Shorten Gedcom name using a limit goal.
    mutating func shortened(to limit: Int) {
        while self.length > limit && initialiseNextMiddleGiven() {}      // Convert middle givens to initials.
        while self.length > limit && removeRightmostOptionalSuffix() {}  // Remove non-keeper suffixes.
        if self.length > limit { _ = initialiseFirstGiven() }            // Make first given an initial.
        while self.length > limit && removeRightmostKeeperSuffix() {}    // Remove keeper suffixes.
        while self.length > limit && removeRightmostMiddleInitial() {}   // Remove middle initials.
                                                                         // Keep the first initial and surname.
    }

    /// Convert next middle given (right-to-left) to initial and return true; return false when no more
    /// middle givens.
    @discardableResult
    private mutating func initialiseNextMiddleGiven() -> Bool {
        guard !parts.isEmpty else { return false }  // Need at least one name part.

        // Find rightmost given to start from.
        let last = lastGivenIndex ?? (parts.count - 1)
        guard last >= 1 else { return false }  // No middle givens to check.
        for i in stride(from: last, through: 1, by: -1) {  // Iterate backwards through middle givens
            let token = parts[i]
            if token.count > 2 {
                initialiseGiven(at: i)
                assert(parts[i].count == 2)  // Prevents looping if initializing goes bad.
                return true
            }
        }
        return false  // No more middle givens to initialise.
    }

    /// Convert first given to an initial. Return true if conversion occurred.
    @discardableResult
    private mutating func initialiseFirstGiven() -> Bool {
        guard let i = firstGivenIndex, !isInitial(parts[i]) else { return false }
        initialiseGiven(at: i)
        return true
    }

    /// Remove rightmost middle initial (not first given), adjusting surnameIndex.
    @discardableResult
    private mutating func removeRightmostMiddleInitial() -> Bool {
        for i in middleGivenIndices.reversed() where isInitial(parts[i]) {
            removePart(at: i)       // your existing helper that shifts surnameIndex
            return true
        }
        return false
    }

    /// Indices strictly between the first given (0) and the surname.
    private var middleGivenIndices: [Int] {
        guard let s = surnameIndex, s > 1 else { return [] }
        return Array(1..<s)
    }

    /// Index of the rightmost given name (immediately left of the surname if present),
    /// or the last part if there is no surname. Returns nil if there is no such part.
    private var lastGivenIndex: Int? {
        if let s = surnameIndex {
            return s > 0 ? s - 1 : nil
        } else {
            return parts.indices.last   // nil if empty
        }
    }

    /// Index of the rightmost suffix token (the last part after the surname), or nil if none.
    private var lastSuffixIndex: Int? {
        guard let s = surnameIndex, s + 1 < parts.count else { return nil }
        return parts.indices.last
    }

    /// Index of the first given (0 if any parts exist)
    private var firstGivenIndex: Int? {
        parts.isEmpty ? nil : 0
    }

    /// "Q." or "Q"
    private func isInitial(_ token: String) -> Bool {
        if token.count == 1, let c = token.first, c.isLetter { return true }
        if token.count == 2, token.last == ".", let c = token.first, c.isLetter { return true }
        return false
    }

    /// Removes a non-keeper suffix and returns true if possible; else returns false.
    @discardableResult
    private mutating func removeRightmostOptionalSuffix() -> Bool {
        guard let r = suffixRange, !r.isEmpty else { return false }
        for i in r.reversed() {
            if !suffixKeeper(parts[i]) {
                parts.remove(at: i)
                return true
            }
        }
        return false
    }

    /// Drop rightmost keeper suffix (Jr/Sr/II/III/IV…). Returns true if removed.
    @discardableResult
    private mutating func removeRightmostKeeperSuffix() -> Bool {
        guard let r = suffixRange, !r.isEmpty else { return false }
        for i in r.reversed() where suffixKeeper(parts[i]) {
            parts.remove(at: i)
            return true
        }
        return false
    }

    /// Range of suffix tokens (those after the surname), or nil if none.
    private var suffixRange: Range<Int>? {
        guard let s = surnameIndex, s + 1 < parts.count else { return nil }
        return (s + 1)..<parts.count
    }
}

/// Returns true for suffixes to keep during the first round of shortening.
private func suffixKeeper(_ suffix: String) -> Bool {
    switch suffix {
    case "Jr", "Sr", "Jr.", "Sr.", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX": return true
    default: return false
    }
}

// Helper function for getting the displayName of a Person.
extension Person {

    public func displayName(upSurname: Bool = false, surnameFirst: Bool = false, limit: Int = 0) -> String {
        guard let name = GedcomName(from: self.root) else { return "(no name)" }
        return name.displayName(upSurname: upSurname, surnameFirst: surnameFirst, limit: limit)
    }
}
