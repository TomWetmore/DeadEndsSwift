//
//  GedcomDate.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 29 June 2025.
//  Last changed on 29 June 2025.
//

import Foundation

// year extracts a year from a Gedcom DATE value.
func year(from rawDate: String?) -> String? {
    guard let raw = rawDate else { return nil }
    let scanner = Scanner(string: raw)
    while !scanner.isAtEnd {
        if let token = scanner.scanCharacters(from: .decimalDigits),
           token.count == 4,
           let _ = Int(token) {
            return token
        }
        _ = scanner.scanUpToCharacters(from: .decimalDigits)
    }
    return nil
}
