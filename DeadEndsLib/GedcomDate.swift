//
//  GedcomDate.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 29 June 2025.
//  Last changed on 20 November 2025.
//

import Foundation

public typealias Year = Int

/// Extract a year String from a String (usually a 1 DATE value).
func year(from value: String?) -> String? {
    guard let raw = value else { return nil }
    let scanner = Scanner(string: raw)
    while !scanner.isAtEnd {
        if let token = scanner.scanCharacters(from: .decimalDigits),
            token.count == 4, Int(token) != nil {
            return token
        }
        _ = scanner.scanUpToCharacters(from: .decimalDigits)
    }
    return nil
}

/// Extract a year String from a 1 DATE GedcomNode.
func year(from dateNode: GedcomNode) -> String? {
    guard let value = dateNode.val else { return nil }
    return year(from: value)
}
