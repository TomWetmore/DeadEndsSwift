//
//  Errors.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 21 December 2025.
//  Last changed on 25 February 2026.
//

import Foundation

///  ErrorType is the type of a DeadEnds Error.
enum ErrorType: String {
	case system = "system"
	case syntax = "syntax"
	case gedcom = "gedcom"
	case linkage = "linkage"
	case validate = "validate"
}

/// Severity is the severity of a DeadEnds Error.
enum Severity: String {
	case fatal = "fatal"   // Quit loading database
	case severe = "severe"  // Continue with source but don't keep database
	case warning = "warning" // Continue with source and load database
	case comment = "comment"  // Message for user
}

/// DeadEnds error.
public struct Error: CustomStringConvertible {
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

    /// Description of error.
    public var description: String {
        var string = "error: \(type.rawValue) \(severity.rawValue)"
        if let line = line { string += " line \(line)" }
        if let source = source { string += " in \(source)" }
        string += ": \(message)"
        return string
    }
}

/// Error log class.
public class ErrorLog: CustomStringConvertible {

    var log: [Error] = []  // Array of errors.
    public var count: Int { return log.count }  // Number of entries in log.

    /// Create an error log.
    public init() {}

    /// Description of error log.
    public var description: String {
        var string = ""
        for entry in log { string += "\n\(entry)" }
        return string
    }

    /// Append an error to the log.
    public func append(_ error: Error) {
        log.append(error)
    }
}
