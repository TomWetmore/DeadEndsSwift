//
//  RefnIndex.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 21 December 2024.
//  Last changed on 28 June 2025.
//

import Foundation

public struct RefnIndex {
	var index: [String:[String]] = [:]  // Maps a REFN to a list of GEDCOM keys

	mutating func add(refn: String, key: String) {
		if index[refn] != nil {
			index[refn]?.append(key)
		} else {
			index[refn] = [key]
		}
	}

	func getKeys(for refn: String) -> [String]? {
		return index[refn]
	}
}
