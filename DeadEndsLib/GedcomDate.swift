//
//  GedcomDate.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 29 June 2025.
//  Last changed on 20 November 2025.
//

import Foundation

public typealias Year = Int

/// Extract year string from a date string (e.g. 1 DATE value).
func oldyear(from value: String?) -> String? {
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

/// Extract year integer from a a date string (e.g. 1 DATE value).
//func yearInt(_ value: String?) -> Year? {
//    return year(from: value).flatMap(Int.init)
//}

