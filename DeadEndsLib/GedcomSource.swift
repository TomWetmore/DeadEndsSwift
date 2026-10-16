//
//  GedcomSource.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 15 October 2026.
//  Last changed on 15 October 2026.
//

import Foundation

/// Source of Gedcom lines.
///
public protocol GedcomSource {

    var name: String { get }
    func makeLineIterator() -> AnyIterator<String>
}

/// GedcomSource for files.
///
public struct FileGedcomSource: GedcomSource {

    public let path: String
    public var name: String { path }

    /// Make iterator to return lines from a file.
    ///
    public func makeLineIterator() -> AnyIterator<String> {

        guard let contents = try? String(contentsOfFile: path, encoding: .utf8)
        else {
            return AnyIterator { nil }
        }
        var lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init).makeIterator()
        return AnyIterator { lines.next() }
    }
}

/// GedcomSource for Strings.
///
public struct StringGedcomSource: GedcomSource {

    public let name: String
    public let content: String

    public init(name: String, content: String) {

        self.name = name
        self.content = content
    }

    /// Make iterator to return lines from a string.
    ///
    public func makeLineIterator() -> AnyIterator<String> {

        var lines = content.split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init).makeIterator()
        return AnyIterator { lines.next() }
    }
}
