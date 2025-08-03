//
//  Database.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 19 Deceber 2024.
//  Last changed on 18 July 2025.
//

import Foundation

// RecordIndex is a dictionary that maps record keys to records.
public typealias RecordIndex = [String: GedcomNode]

/// KeyMap is a dictionary used when building a database; it maps record keys to the lines where records begin.
public typealias KeyMap = [String : Int]

/// `RootList` is an array of records (level 0 `GedcomNode`s).
public typealias RootList = [GedcomNode]

/// `Database` is the DeadEnds in-RAM database.
///
/// A `Database` is created from a Gedcom file.
public class Database {

    /// Index of all GedcomNode records in the database.
	public private(set) var recordIndex: RecordIndex

    /// Copy of the header record from the Gedcom file.
    public private(set) var header: GedcomNode?

    /// Index of Person names; maps the keys of 1 NAME values to person record sets.
	public var nameIndex: NameIndex

    /// Index of 1 REFN values.
	public var refnIndex: RefnIndex

    /// Single copies of tag strings.
	public var tagmap: TagMap

    /// Set when `Database` changes.
	var dirty: Bool = false

    /// Creates and initializes a `Database`.
    init(recordIndex: RecordIndex, nameIndex: NameIndex,
             refnIndex: RefnIndex, tagmap: TagMap, dirty: Bool = false)
     {
        self.recordIndex = recordIndex
        self.nameIndex = nameIndex
        self.refnIndex = refnIndex
        self.tagmap = tagmap
        self.dirty = dirty
    }
}

extension Database {

    /// Returns the Array of all Persons in the database.
    var persons: [GedcomNode] {
        recordIndex.values.filter { $0.tag == "INDI" }
    }

    /// Returns the array of all Families in the database.
    var families: [GedcomNode] {
        recordIndex.values.filter { $0.tag == "FAM" }
    }

    /// Returns the number of Persons in the database.
    var personCount: Int {
        recordIndex.values.lazy.filter { $0.tag == "INDI" }.count
    }

    /// Returns the number of Families in the database.
    var familyCount: Int {
        recordIndex.values.lazy.filter { $0.tag == "FAM" }.count
    }
}

/// Attempts to create a DeadEnds `Database` for each path in a list. The databases are returned in an
/// array. This function is not used yet, anticipating future applications that deal with mulitple databases.
public func getDatabasesFromPaths(paths: [String], errlog: inout ErrorLog) -> [Database]? {
	var databases = [Database]()
	for path in paths {
		if let database = getDatabaseFromPath(path, errlog: &errlog) {
			databases.append(database)
		}
	}
	return databases.count > 0 ? databases : nil
}

/// Creates a DeadEnds `Database` from a Gedcom path. If there are errors no database is created and
/// `errlog` holds the errors.
///
/// Parameters
/// - `path`: path to Gedcom file.
/// - `errlog`: reference to an `ErrorLog` (`[Error]`).
public func getDatabaseFromPath(_ path: String, errlog: inout ErrorLog) -> Database? {
    let source = FileGedcomSource(path: path)
    return getDatabaseFromSource(source, errlog: &errlog)
}

public func getDatabaseFromSource(_ source: GedcomSource, errlog: inout ErrorLog) -> Database? {
    var keymap = KeyMap() // Maps record keys to the lines where defined.
    var tagmap = TagMap() // So there is only one copy of each tag.

    guard let (index, persons, families) = getValidRecordsFromSource(source: source, tagmap: &tagmap, keymap: &keymap,
                                                                     errlog: &errlog)
    else { return nil } // errlog holds the errors.

    let nameIndex = getNameIndex(persons: persons)
    // let refnIndex = getRefnIndex(persons: persons) // Implement when ready.

    return Database(recordIndex: index,
                    nameIndex: nameIndex,
                    refnIndex: RefnIndex(),
                    tagmap: tagmap)
}




extension Database {

    /// Returns the list of keys of all persons with a name that matches.
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

    /// Returns the array of persons who have names that match name.
    public func persons(withName name: String) -> [Person] {
        personKeys(forName: name).compactMap { recordIndex[$0] }
    }
}

