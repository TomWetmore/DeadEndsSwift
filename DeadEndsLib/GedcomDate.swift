//
//  GedcomDate.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 29 June 2025.
//  Last changed on 27June 2026.
//

import Foundation

public typealias Year = Int

/// Extract year from a date value string.
func year(from value: String?) -> Year? {
    guard let raw = value else { return nil }
    let scanner = Scanner(string: raw)
    while !scanner.isAtEnd {
        if let token = scanner.scanCharacters(from: .decimalDigits),
           token.count == 4,
           let y = Year(token) {
            return y
        }
        _ = scanner.scanUpToCharacters(from: .decimalDigits)
    }
    return nil
}

/// Extract year from a 1 DATE node.
func year(from dateNode: GedcomNode) -> Year? {
    guard let value = dateNode.val else { return nil }
    return year(from: value)
}
