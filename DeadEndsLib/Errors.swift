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

// Struct that holds a DeadEnds error.
public struct Error {
	let type: ErrorType
	let severity: Severity
	let source: String?
	let line: Int?
	public let message: String

    /// Create an error.
	init(type: ErrorType, severity: Severity, source: String? = nil, line: Int? = 0,
		 message: String) {
		self.type = type
		self.severity = severity
		self.source = source
		self.line = line
		self.message = message
	}
}

/// Error log class.
public class ErrorLog {

    var log: [Error] = []  // Array of errors.
    public var count: Int { return log.count }  // Number of entries in log.

    /// Create an error log.
    public init() {}

    /// Append an error to the log.
    public func append(_ error: Error) {
        log.append(error)
    }
}
