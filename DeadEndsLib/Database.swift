//
//  Database.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 19 December 2024.
//  Last changed on 27 November 2025.
//

import Foundation

public typealias RecordKey = String
public typealias RecordIndex = [RecordKey: GedcomNode]  // Maps keys to root nodes.
public typealias KeyMap = [RecordKey : Int]  // Maps keys to line numbers (from GedcomSource).
public typealias RecordList = [GedcomNode]  // List of Records (level 0 GedcomNodes.

/// Database is the DeadEnds in-RAM database. It is created from a GedcomSource. All genealogical data
/// is found in a Database.
final public class Database {

	public internal(set) var recordIndex: RecordIndex  // Index of all keyed Records.
    public private(set) var header: GedcomNode?  // Header Record.
    public private(set) var persons: RecordList = []  // List of all Persons.
    public private(set) var families: RecordList = []  // List of all Families.
	public var nameIndex: NameIndex  // Person name index.
    public var dateIndex: DateIndex  // Records data index.
    public var placeIndex: PlaceIndex  // Person (so far) place index.
	public var refnIndex: RefnIndex  // Reference value index.
	public var tagmap: TagMap  // Single copies of all tag Strings.
    var dirty: Bool = false  // Set when Database changes.

    var personCount: Int { persons.count }  // Number of Persons in Database.
    var familyCount: Int { families.count }  // Number of Families in Database.

    /// Initializes a Database; all arguments should exist.
    init(recordIndex: RecordIndex, persons: RecordList, families: RecordList,
         header: GedcomNode?, nameIndex: NameIndex, dateIndex: DateIndex, placeIndex: PlaceIndex,
         refnIndex: RefnIndex, tagmap: TagMap, dirty: Bool = false) {

        self.recordIndex = recordIndex
        self.persons = persons
        self.families = families
        self.header = header
        self.nameIndex = nameIndex
        self.dateIndex = dateIndex
        self.placeIndex = placeIndex
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

/// Loads a Database from a GedcomSource. The keyMap does not persist: it is used to generate
/// error message. The tagMap persists as a property of the Database.
public func loadDatabase(from source: GedcomSource, errlog: inout ErrorLog) -> Database? {

    var keyMap = KeyMap()  // Maps record keys to their defining lines; for error messages.
    var tagMap = TagMap()  // Keeps a single copy of each tag; to save memory.

    // Attempt to read the records from the Gedcom source. This also validates the records.
    guard let (index, persons, families, header) =
            loadValidRecords(from: source, tagMap: &tagMap, keyMap: &keyMap, errlog: &errlog)
    else { return nil }  // errlog holds the errors.
    print("Loaded \(persons.count) persons, \(families.count) families.")

    // Create the three indexes for person names, and event dates and places.
    let nameIndex = buildNameIndex(from: persons)
    let dateIndex = buildDateIndex(from: index)
    let placeIndex = buildPlaceIndex(from: persons)
    //placeIndex.showContents(using: index)  // DEBUG
    //showPlaceFrequencyTable(placeIndex)  // DEBUG
    //dateIndex.showContents(using: index)  // DEBUG
    // let refnIndex = buildRefnIndex(from: index) // Implement when ready.
    return Database(recordIndex: index, persons: persons, families: families, header: header,
                    nameIndex: nameIndex, dateIndex: dateIndex, placeIndex: placeIndex, refnIndex: RefnIndex(),
                    tagmap: tagMap, dirty: false)
}



