//
//  Errors.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 21 December 2025.
//  Last changed on 7 April 2025.
//

import Foundation

//  ErrorType is the type of a DeadEnds Error.
enum ErrorType {
	case system
	case syntax
	case gedcom
	case linkage
	case validate
}

// Severity is the severity of a DeadEnds Error.
enum Severity {
	case fatal   // Quit loading database
	case severe  // Continue with source but don't keep database
	case warning // Continue with source and load database
	case comment  // Message for user
}

// Error is the struct that holds a DeadEnds Error.
public struct Error {
	let type: ErrorType
	let severity: Severity
	let source: String?
	let line: Int?
	let message: String

	init(type: ErrorType, severity: Severity, source: String? = nil, line: Int? = 0,
		 message: String) {
		self.type = type
		self.severity = severity
		self.source = source
		self.line = line
		self.message = message
	}
}

// ErrorLog is an array of Errors.
public typealias ErrorLog = [Error]
