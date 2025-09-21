//
//  GedcomName.swift
//  DeadEnds Library
//
//  Created by Thomas Wetmore on 1 January 2025.
//  Last changed on 10 September 2025.
//

import Foundation

/// Internal representation of a Gedcom 1NAME value.
public struct GedcomName: Comparable, CustomStringConvertible {

    var nameParts: [String]  // Name parts, before surname, surname, and after surname.
    var surnameIndex: Int?  // Index of surname if it exists.

    /// Initializer using precomupted structure properties.
    private init(nameParts: [String], surnameIndex: Int?) {
        self.nameParts = nameParts
        if let s = surnameIndex, s >= 0, s < nameParts.count { self.surnameIndex = s }
        else { self.surnameIndex = nil }
    }

    /// Initializer for GedcomName using a Gedcom formatted name string as used in 1 NAME values.
    public init?(string: String) {
        guard let (parts, sindex) = parseGedcomName(value: string) else { return nil }
        self.init(nameParts: parts, surnameIndex: sindex)
    }

    /// Initializer for GedcomName from a 0INDI or 0INDI:1NAME node.
    public init?(from node: GedcomNode) {
        let nameNode: GedcomNode? = (node.tag == "NAME") ? node : node.kid(withTag: "NAME")
        guard let value = nameNode?.val else { return nil }
        self.init(string: value)
    }

    /// Returns a String description of a GedcomName showing its internal struture.
    public var description: String {
        let parts = nameParts.enumerated()
            .map { idx, part in
                if idx == surnameIndex { return "[\(part)]" }  // Highlight the surname.
                else { return part }
            }.joined(separator: " | ")
        return "GedcomName(parts: \(parts), surnameIndex: \(surnameIndex?.description ?? "nil"))"
    }

    /// Returns the character length of a GedcomName.
    /// In future may want to measure rendered text.
    public var length: Int {
        return nameParts.count - 1 + nameParts.reduce(0) { $0 + $1.count }
    }

    /// Returns text to use to display a name in a text View.
    public func displayName(upSurname: Bool = false, surnameFirst: Bool = false, limit: Int = 0) -> String {
        var work = self
        if upSurname { work.uppercaseSurname() }
        if limit > 0 { work.shortened(to: limit) }
        return work.format(surnameFirst: surnameFirst)
    }

    /// Formats a GNodeName to a String.
    func format(surnameFirst: Bool) -> String {
        guard !nameParts.isEmpty else { return "" }
        if surnameFirst, let si = surnameIndex {  // Handle the surname first case.
            let surname = nameParts[si]
            let before = nameParts[..<si]
            let after = nameParts[(si + 1)..<nameParts.count]
            let rest = (before + after).joined(separator: " ")  // Join givens and suffixes.
            return rest.isEmpty ? surname : "\(surname), \(rest)"
        } else {
            return nameParts.joined(separator: " ")  // Else join all parts in order.
        }
    }

    /// Returns the DeadEnds name key of this GedcomName.
    var nameKey: String {
        let firstInitial = firstInitial ?? "$"
        let surname = surname ?? ""
        return "\(firstInitial)\(soundex(for: surname))"
    }

    /// First initial (uppercased) of the first given name, or nil.
    var firstInitial: Character? {
        return nameParts.first?.first(where: \.isLetter)?.uppercased().first
    }

    /// Surname of the GedcomName if it exists, else nil.
    var surname: String? {
        if surnameIndex == nil { return nil }
        return nameParts[surnameIndex!]
    }

    /// Returns array of the the name parts, excluding the surname, in lower case.
    var lowercaseGivens: [String] {
        nameParts.enumerated()
            .compactMap { (i, part) in
                i == surnameIndex ? nil : part.lowercased()
            }
    }

    /// Uppercases the surname in situ if it exists.
    mutating func uppercaseSurname() {
        guard let i = surnameIndex else { return }
        nameParts[i] = nameParts[i].uppercased()
    }

    /// Converts a given name to an initial with a period in situ. Does not affect surname.
    mutating func initialiseGiven(at i: Int) {
        guard i >= 0 && i < nameParts.count && i != surnameIndex else { return }
        if let c = nameParts[i].first { nameParts[i] = "\(c)." }
    }

    /// Removes a name part. Note: Will not remove surname.
    mutating func removePart(at i: Int) {
        guard i >= 0 && i < nameParts.count && i != surnameIndex else { return }
        nameParts.remove(at: i)
        if let s = surnameIndex, i < s { surnameIndex = s - 1 }
        else if surnameIndex == i { surnameIndex = nil }
    }

    /// Removes suffixes (I think). I don't think this will be useful.
    mutating func dropSuffix(range: Range<Int>) {
        guard !range.isEmpty else { return }
        nameParts.removeSubrange(range)
        if let s = surnameIndex, range.lowerBound <= s {
            surnameIndex = s - min(s - range.lowerBound, range.count)
        }
    }

    /// Compares two GedcomNames according to surname, initial, and given name order
    func compare(to other: GedcomName) -> ComparisonResult {

        // First compare surnames.
        let s1 = surname?.lowercased() ?? ""
        let s2 = other.surname?.lowercased() ?? ""
        let r1 = s1.compare(s2)
        if r1 != .orderedSame { return r1  }

        // Second compare first initials.
        switch (firstInitial, other.firstInitial) {
        case let (a?, b?) where a != b:
            return a < b ? .orderedAscending : .orderedDescending
        case (.some, .none): return .orderedAscending
        case (.none, .some): return .orderedDescending
        default: break
        }

        // Third go whole hog on the given names.
        for (a, b) in zip(lowercaseGivens, other.lowercaseGivens) {
            let cmp = a.compare(b)
            if cmp != .orderedSame { return cmp }
        }

        // If one has more remaining
        if lowercaseGivens.count < other.lowercaseGivens.count { return .orderedAscending }
        if lowercaseGivens.count > other.lowercaseGivens.count { return .orderedDescending }

        return .orderedSame
    }

    public static func < (lhs: GedcomName, rhs: GedcomName) -> Bool {
        lhs.compare(to: rhs) == .orderedAscending
    }
}

/// Parses a Gedcom name String into the constituents of a GedcomName.
private func parseGedcomName(value: String) -> (parts: [String], surnameIndex: Int?)? {

    if value.isEmpty { return nil }

    /// Squeeze whitespace into single spaces.
    func squeeze(_ s: String) -> String {
        s.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }
    let val = squeeze(value)

    // Get the indexes of all slashes.
    let slashIdxs = val.indices.filter { val[$0] == "/" }

    /// Split a String to space separated tokens.
    func tokens(_ s: String) -> [String] {
        s.isEmpty ? [] : s.split(separator: " ").map(String.init)
    }

    switch slashIdxs.count {
    case 0:
        // No slashes: all given, no surname.
        let givens = tokens(value)
        return (givens, nil)

    case 1:
        // One slash: surname from that slash to end.
        let first = slashIdxs[0]
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
        // >= 2 slashes: FIRST opens, LAST closes. Inside-extra slashes -> spaces.
        let first = slashIdxs.first!
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

extension Person {

    func displayName(upSurname: Bool = false, surnameFirst: Bool = false, length: Int? = nil) -> String? {
        // Get the GedcomName of the person.
        guard var gedcomname = GedcomName(from: self.root) else { return nil }

        if upSurname { gedcomname.uppercaseSurname() }  // Handle the upSurname flag.

        // Handle shortening
        if let length = length { gedcomname.shortened(to: length) }  // Handle shortening.

        return gedcomname.format(surnameFirst: surnameFirst)
    }
}

// Methods for shortening GedcomNames.
extension GedcomName {

    /// Shortens a GedcomName using a limit goal.
    mutating func shortened(to limit: Int) {

        while self.length > limit && initialiseNextMiddleGiven() {}      // Convert middle givens to initials.
        while self.length > limit && removeRightmostOptionalSuffix() {}  // Remove non-keeper suffixes.
        if self.length > limit { _ = initialiseFirstGiven() }            // Make first given an initial.
        while self.length > limit && removeRightmostKeeperSuffix() {}    // Remove keeper suffixes.
        while self.length > limit && removeRightmostMiddleInitial() {}   // Remove middle initials.
                                                                         // Keep the first initial and surname.
    }

    /// Converts the next middle given (right-to-left) to an initial and return true. Returns false
    /// when there are no more middle givens.
    @discardableResult
    private mutating func initialiseNextMiddleGiven() -> Bool {
        guard !nameParts.isEmpty else { return false }  // Need at least one name part.

        // Find rightmost given to start from.
        let last = lastGivenIndex ?? (nameParts.count - 1)
        guard last >= 1 else { return false }  // No middle givens to check.
        for i in stride(from: last, through: 1, by: -1) {  // Iterate backwards through middle givens
            let token = nameParts[i]
            if token.count > 2 {
                initialiseGiven(at: i)
                assert(nameParts[i].count == 2)  // Prevents looping if initializing goes bad.
                return true
            }
        }
        return false  // No more middle givens to initialise.
    }

    /// Converts the first given name to an initial. Returns true if the conversion occurred.
    @discardableResult
    private mutating func initialiseFirstGiven() -> Bool {
        guard let i = firstGivenIndex, !isInitial(nameParts[i]) else { return false }
        initialiseGiven(at: i)
        return true
    }

    /// Remove the rightmost middle **initial** (not the first given), adjusting `surnameIndex`.
    @discardableResult
    private mutating func removeRightmostMiddleInitial() -> Bool {
        for i in middleGivenIndices.reversed() where isInitial(nameParts[i]) {
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
            return nameParts.indices.last   // nil if empty
        }
    }

    /// Index of the rightmost suffix token (the last part after the surname), or nil if none.
    private var lastSuffixIndex: Int? {
        guard let s = surnameIndex, s + 1 < nameParts.count else { return nil }
        return nameParts.indices.last
    }

    /// Index of the first given (0 if any parts exist)
    private var firstGivenIndex: Int? {
        nameParts.isEmpty ? nil : 0
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
            if !suffixKeeper(nameParts[i]) {
                nameParts.remove(at: i)
                return true
            }
        }
        return false
    }

    /// Drop rightmost keeper suffix (Jr/Sr/II/III/IV…). Returns true if removed.
    @discardableResult
    private mutating func removeRightmostKeeperSuffix() -> Bool {
        guard let r = suffixRange, !r.isEmpty else { return false }
        for i in r.reversed() where suffixKeeper(nameParts[i]) {
            nameParts.remove(at: i)
            return true
        }
        return false
    }

    /// Range of suffix tokens (those after the surname), or nil if none.
    private var suffixRange: Range<Int>? {
        guard let s = surnameIndex, s + 1 < nameParts.count else { return nil }
        return (s + 1)..<nameParts.count
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
