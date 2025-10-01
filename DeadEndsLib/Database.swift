//
//  Database.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 19 December 2024.
//  Last changed on 26 September 2025.
//

import Foundation

public typealias RecordIndex = [String: GedcomNode]  // Maps keys to records.
//public typealias RecordIndex = [String: Record]  // Maps keys to Records.
public typealias KeyMap = [String : Int]  // Maps keys to line numbers.
public typealias RecordList = [GedcomNode]  // List of Records (level 0 GedcomNodes.
//public typealias RecordList = [Record]  // List of Records (level 0 GedcomNodes.

/// Database is the DeadEnds in-RAM database. It is created from a GedcomSource.
public class Database {

	public internal(set) var recordIndex: RecordIndex  // Index of all keyed Records.
    public private(set) var header: GedcomNode?  // Header Record.
    public private(set) var persons: RecordList = []  // List of all Persons.
    public private(set) var families: RecordList = []  // List of all Families.
	public var nameIndex: NameIndex  // Person name index.
	public var refnIndex: RefnIndex  // Reference value index.
	public var tagmap: TagMap  // Single copy of all tags.
    var dirty: Bool = false  // Set when Database changes.

    var personCount: Int { persons.count }  // Number of Persons in Database.
    var familyCount: Int { families.count }  // Number of Families in Database.

    /// Initializes a Database; all arguments should exist.
    init(recordIndex: RecordIndex, persons: RecordList, families: RecordList,
         header: GedcomNode?, nameIndex: NameIndex, refnIndex: RefnIndex, tagmap: TagMap,
         dirty: Bool = false) {

        self.recordIndex = recordIndex
        self.persons = persons
        self.families = families
        self.header = header
        self.nameIndex = nameIndex
        self.refnIndex = refnIndex
        self.tagmap = tagmap
        self.dirty = dirty
    }
}

/// Loads an Array of Databases for each path in a list. This function isn't used yet.
public func loadDatabases(from paths: [String], errlog: inout ErrorLog) -> [Database]? {
	var databases = [Database]()
	for path in paths {
        if let database = loadDatabase(from: path, errlog: &errlog) {
			databases.append(database)
		}
	}
	return databases.count > 0 ? databases : nil
}

/// Loads a Database from a Gedcom file. No Database is created if there are errors.
public func loadDatabase(from path: String, errlog: inout ErrorLog) -> Database? {
    let source = FileGedcomSource(path: path)
    return loadDatabase(from: source, errlog: &errlog)
}

/// Loads a Database from a GedcomSource. keyMap does not persist; tagMap is specific to a single Database.
public func loadDatabase(from source: GedcomSource, errlog: inout ErrorLog) -> Database? {
    var keyMap = KeyMap()  // Maps record keys to their defining lines; for error messages.
    var tagMap = TagMap()  // Keeps a single copy of each tag; to save memory.

    guard let (index, persons, families, header) =
            loadValidRecords(from: source, tagMap: &tagMap, keyMap: &keyMap, errlog: &errlog)
    else { return nil }  // errlog holds the errors.
    let nameIndex = buildNameIndex(from: persons)
    // let refnIndex = buildRefnIndex(from: index) // Implement when ready.
    return Database(recordIndex: index, persons: persons, families: families, header: header,
                    nameIndex: nameIndex, refnIndex: RefnIndex(), tagmap: tagMap, dirty: false)
}



