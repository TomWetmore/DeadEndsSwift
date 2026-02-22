//
//  Database.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 19 December 2024.
//  Last changed on 19 February 2026.
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
	public var tagMap: TagMap  // Single copies of tag Strings.
    var dirty: Bool = false

    var personCount: Int { persons.count }
    var familyCount: Int { families.count }

    /// Create a database.
    init(recordIndex: RecordIndex, persons: RecordList, families: RecordList,
         header: GedcomNode?, nameIndex: NameIndex, dateIndex: DateIndex, placeIndex: PlaceIndex,
         refnIndex: RefnIndex, tagMap: TagMap, dirty: Bool = false) {

        self.recordIndex = recordIndex
        self.persons = persons
        self.families = families
        self.header = header
        self.nameIndex = nameIndex
        self.dateIndex = dateIndex
        self.placeIndex = placeIndex
        self.refnIndex = refnIndex
        self.tagMap = tagMap
        self.dirty = dirty
    }
}

/// Load an array of databasea from paths in a list. This function is not used.
public func loadDatabases(from paths: [String], errlog: inout ErrorLog) -> [Database] {
	var databases = [Database]()
	for path in paths {
        if let database = loadDatabase(from: path, errlog: &errlog) {
			databases.append(database)
		}
	}
	return databases
}

/// Load a database from a Gedcom filel if there are errors no database is created.
public func loadDatabase(from path: String, errlog: inout ErrorLog) -> Database? {
    let source = FileGedcomSource(path: path)
    return loadDatabase(from: source, errLog: &errlog)
}

/// Load a database from a source; keyMap is used for error messages and does not persist.
private func loadDatabase(from source: GedcomSource, errLog: inout ErrorLog) -> Database? {

    var keyMap = KeyMap()  // Map record keys to lines.
    let tagMap = TagMap()  // Single copies of tags.

    guard let (index, persons, families, header) =  // Read and validate the records.
            loadValidRecords(from: source, tagMap: tagMap, keyMap: &keyMap, errlog: errLog)
    else { return nil }  // errlog holds the errors.
    print("Loaded \(persons.count) persons, \(families.count) families.")

    let nameIndex = buildNameIndex(from: persons)  // Create indexes.
    let dateIndex = buildDateIndex(from: index)
    let placeIndex = buildPlaceIndex(from: index)
    let refnIndex = validateRefns(from: index, keyMap: keyMap, errLog: errLog)

    //placeIndex.showContents(using: index)  // DEBUG
    //placeIndex.showPlaceFrequencyTable()  // DEBUG
    //dateIndex.showContents(using: index)  // DEBUG
    //refnIndex.showContents()  // DEBUG
    if errLog.count > 0 { return nil }
    return Database(recordIndex: index, persons: persons, families: families, header: header,
                    nameIndex: nameIndex, dateIndex: dateIndex, placeIndex: placeIndex, refnIndex: refnIndex,
                    tagMap: tagMap, dirty: false)
}



