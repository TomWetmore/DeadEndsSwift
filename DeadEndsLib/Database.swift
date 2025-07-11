//
//  Database.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 19 Deceber 2024.
//  Last changed on 29 June 2025.
//

import Foundation

// RecordIndex is a dictionary that maps record keys to records.
public typealias RecordIndex = [String: GedcomNode]

// KeyMap is a dictionary used when building a database; it maps record keys to the lines where records begin.
typealias KeyMap = [String : Int]

// RootList is an array of records, that is, 0 level nodes.
public typealias RootList = [GedcomNode]

// Database is the struct for the DeadEnds in-RAM Database.
public class Database {
	public private(set) var recordIndex: RecordIndex // Complete record index.
	public private(set) var personIndex: RootList // Array of all persons.
	public private(set) var familyIndex: RootList // Array of all familes.
    public private(set) var header: GedcomNode? // Header record.
	public private(set) var nameIndex: NameIndex // Index of all 1 NAME values to record key sets.
	public private(set) var refnIndex: RefnIndex // Index of all 1 REFN vaules to ...
	var tagmap: TagMap // Single copies of all tag strings.
	var dirty: Bool = false

    init(recordIndex: RecordIndex, persons: RootList, families: RootList, nameIndex: NameIndex,
         refnIndex: RefnIndex, tagmap: TagMap, dirty: Bool = false) {
        self.recordIndex = recordIndex
        self.personIndex = persons
        self.familyIndex = families
        self.nameIndex = nameIndex
        self.refnIndex = refnIndex
        self.tagmap = tagmap
        self.dirty = dirty

    }
}

// getDatabasesFromPaths trys to create a database for each path in a list. The databases are returned in an optioinal
// array. This function is not used yet, anticipating future applications that deal with mulitple databases.
public func getDatabasesFromPaths(paths: [String], errlog: inout ErrorLog) -> [Database]? {
	var databases = [Database]()
	for path in paths {
		if let database = getDatabaseFromPath(path, errlog: &errlog) {
			databases.append(database)
		}
	}
	return databases.count > 0 ? databases : nil
}

// getDatabaseFromPath trys to create a database for a Gedcom path. If there are errors no database is created and
// errlog will hold the errors. Path names a Gedcom file; future extensions may allow other sources of Gedcom data.
// Calls getValidRecordsFromPath to get the record index and person and family root lists. If all is okay the name
// and refn indexes are created, and the database is returned.
public func getDatabaseFromPath(_ path: String, errlog: inout ErrorLog) -> Database? {
	var keymap = KeyMap() // Maps record keys to the lines where defined.
	var tagmap = TagMap() // So there is only one copy of each tag.
	guard let (index, persons, families) = getValidRecordsFromPath(path: path, tagmap: &tagmap, keymap: &keymap,
																   errlog: &errlog)
	else { return nil } // errlog holds the errors.
	let nameIndex = getNameIndex(persons: persons)
	//var refnIndex = getRefnIndex(persons: persons) // GET THIS WRITTEN!!
	return Database(recordIndex: index, persons: persons, families: families,
					nameIndex: nameIndex, refnIndex: RefnIndex(), tagmap: tagmap)
}

extension Database {

    // personKeys(name:) returns the list of keys of all persons with a name that matches.
    public func personKeys(forName name: String) -> [String] {
        var matchingKeys: [String] = []
        let nameKey = nameKey(from: name) // Name key of name.
        guard let namekeys = nameIndex.index[nameKey] else { return [] }

        let squeezedPattern: [String] = squeeze(name) // Prepare name for matching.

        // Filter candidates based on exactMatch logic.
        for recordKey in namekeys {
            if let person = recordIndex[recordKey] {
                for personName in person.names() {
                    let squeezedPersonName = squeeze(personName)
                    if exactMatch(partial: squeezedPattern, complete: squeezedPersonName) {
                        matchingKeys.append(recordKey)
                        break // Don't check other names of this person.
                    }
                }
            }
        }
        return matchingKeys
    }

    // persons(withName:) returns the array of persons who have names that match name.
    public func persons(withName name: String) -> [Person] {
        personKeys(forName: name).compactMap { recordIndex[$0] }
    }
}

