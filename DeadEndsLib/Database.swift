//
//  Database.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 19 December 2024.
//  Last changed on 4 February 2026.
//

import Foundation

public typealias RecordKey = String
public typealias RecordIndex = [RecordKey: GedcomNode]
public typealias KeyMap = [RecordKey : Int]  // Map keys to source line numbers.
public typealias RecordList = [GedcomNode]

/// DeadEnds in-RAM database.
final public class Database {

	public internal(set) var recordIndex: RecordIndex  // Index of all records.
    public private(set) var header: GedcomNode?  // Header record.
    public private(set) var persons: RecordList = []  // List of persons.
    public private(set) var families: RecordList = []  // List of families.
	public var nameIndex: NameIndex
    public var dateIndex: DateIndex
    public var placeIndex: PlaceIndex
	public var refnIndex: RefnIndex
	public var tagmap: TagMap  // Single copies of all tag Strings.
    var dirty: Bool = false  // Set when Database changes.

    var personCount: Int { persons.count }  // Number of persons.
    var familyCount: Int { families.count }  // Number of families.

    /// Create a database; all arguments must exist.
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

/// Load an array of database from each path in a list. This function isn't used yet.
public func loadDatabases(from paths: [String], errlog: inout ErrorLog) -> [Database] {
	var databases = [Database]()
	for path in paths {
        if let database = loadDatabase(from: path, errlog: &errlog) {
			databases.append(database)
		}
	}
	return databases
}

/// Load a database from a Gedcom file. No Database is created if there are errors.
public func loadDatabase(from path: String, errlog: inout ErrorLog) -> Database? {
    let source = FileGedcomSource(path: path)
    return loadDatabase(from: source, errlog: &errlog)
}

/// Load database from a source; keyMap is used in error messages and does not persist;
/// tagMap persists as a database property.
private func loadDatabase(from source: GedcomSource, errlog: inout ErrorLog) -> Database? {

    var keyMap = KeyMap()  // Map keys to lines for error messages.
    var tagMap = TagMap()  // Sngle copy of each tag in database.

    // Read and validate the records from the source.
    guard let (index, persons, families, header) =
            loadValidRecords(from: source, tagMap: &tagMap, keyMap: &keyMap, errlog: &errlog)
    else { return nil }  // errlog holds the errors.
    print("Loaded \(persons.count) persons, \(families.count) families.")

    // Create indexes.
    let nameIndex = buildNameIndex(from: persons)
    let dateIndex = buildDateIndex(from: index)
    let placeIndex = buildPlaceIndex(from: persons)
//  let refnIndex = buildRefnIndex(from: index) // Implement when ready.

    //placeIndex.showContents(using: index)  // DEBUG
    //showPlaceFrequencyTable(placeIndex)  // DEBUG
    //dateIndex.showContents(using: index)  // DEBUG

    return Database(recordIndex: index, persons: persons, families: families, header: header,
                    nameIndex: nameIndex, dateIndex: dateIndex, placeIndex: placeIndex, refnIndex: RefnIndex(),
                    tagmap: tagMap, dirty: false)
}



