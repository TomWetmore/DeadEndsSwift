//
//  Database.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 19 December 2024.
//  Last changed on 11 March 2026.
//

import Foundation

public typealias RecordKey = String
public typealias RecordIndex = [RecordKey: GedcomNode]
public typealias KeyMap = [RecordKey : Int]  // Map keys to source line numbers.
public typealias RecordList = [GedcomNode]

/// DeadEnds in-RAM database.
final public class Database {

	public internal(set) var recordIndex: RecordIndex
    public private(set) var header: GedcomNode?
    public private(set) var persons: RecordList = []
    public private(set) var families: RecordList = []
	public var nameIndex: NameIndex
    public var dateIndex: DateIndex
    public var placeIndex: PlaceIndex
	public var refnIndex: RefnIndex
    var dirty: Bool = false

    var personCount: Int { persons.count }
    var familyCount: Int { families.count }

    /// Create a database.
    init(recordIndex: RecordIndex, persons: RecordList, families: RecordList,
         header: GedcomNode?, nameIndex: NameIndex, dateIndex: DateIndex, placeIndex: PlaceIndex,
         refnIndex: RefnIndex, dirty: Bool = false) {

        self.recordIndex = recordIndex
        self.persons = persons
        self.families = families
        self.header = header
        self.nameIndex = nameIndex
        self.dateIndex = dateIndex
        self.placeIndex = placeIndex
        self.refnIndex = refnIndex
        self.dirty = dirty
    }

    init?(records: [GedcomNode]) {
        return nil
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

/// Load database from source; keyMap is used for error messages and does not persist.
private func loadDatabase(from source: GedcomSource, errLog: inout ErrorLog) -> Database? {

    var keyMap = KeyMap()  // Map record keys to lines in source.

    guard let (index, persons, families, header) =  // Read and validate records.
            loadValidRecords(from: source, keyMap: &keyMap, errlog: errLog)
    else { return nil }  // errlog holds the errors.
    print("Loaded \(persons.count) persons, \(families.count) families.")

    let nameIndex = buildNameIndex(from: persons)  // Create indexes.
    let dateIndex = buildDateIndex(from: index)
    let placeIndex = buildPlaceIndex(from: index)
    let refnIndex = RefnIndex()  // Awaiting change to the index.
    //let refnIndex = validateRefns(from: index, keyMap: keyMap, errLog: errLog)

    //placeIndex.showContents(using: index)  // DEBUG
    //placeIndex.showPlaceFrequencyTable()  // DEBUG
    //dateIndex.showContents(using: index)  // DEBUG
    //refnIndex.showContents()  // DEBUG
    if errLog.count > 0 { return nil }
    return Database(recordIndex: index, persons: persons, families: families, header: header,
                    nameIndex: nameIndex, dateIndex: dateIndex, placeIndex: placeIndex,
                    refnIndex: refnIndex, dirty: false)
}

extension Database {

    /// Return new database with random record keys and key references.
    func rekeyedDatabase() -> Database? {
        var rekeyMap: [RecordKey: RecordKey] = [:]  // Old key to new key map.

        for (key, root) in recordIndex {  // Create old to new key map.
            rekeyMap[key] = generateRandomKey(prefix: typeLetter(root.tag), map: rekeyMap)
        }
        var newRoots: [GedcomNode] = []
        newRoots.reserveCapacity(recordIndex.count)
        for (_, root) in recordIndex {  // Deep copy records, rewriting keys and references.
            let newRoot = copyTreeRekeying(root, keyTable: rekeyMap)
            newRoots.append(newRoot)
        }
        return Database(records: newRoots)  // Return new database.
    }

    /// Rekey a record index into a new index.
    public func rekeyRecordIndex() -> RecordIndex {
        var rekeyMap: [RecordKey : RecordKey] = [:]
        for (key, root) in recordIndex {
            rekeyMap[key] = generateRandomKey(prefix: typeLetter(root.tag), map: rekeyMap)
        }
        var newRoots: [Root] = []
        newRoots.reserveCapacity(recordIndex.count)
        for (_, root) in recordIndex {  // Deep copy records, rewriting keys and references.
            let newRoot = copyTreeRekeying(root, keyTable: rekeyMap)
            newRoots.append(newRoot)
        }
        var newIndex = RecordIndex()
        newRoots.forEach() { newIndex[$0.key!] = $0 }
        return newIndex
    }

    /// Deep copy Gedcom tree rewriting keys and key refs; recurse kids but iterate sibs.
    private func copyTreeRekeying(_ node: GedcomNode, keyTable: [RecordKey: RecordKey]) -> GedcomNode {
        let newNode = GedcomNode(key: rekeyKey(node.key, keyTable: keyTable), tag: node.tag,
                                 val: rekeyVal(node.val, keyTable: keyTable))
        var oldKid = node.kid
        var prevNewKid: GedcomNode? = nil
        while let child = oldKid {
            let newKid = copyTreeRekeying(child, keyTable: keyTable)
            newKid.dad = newNode
            if prevNewKid == nil {
                newNode.kid = newKid
            } else {
                prevNewKid?.sib = newKid
            }
            prevNewKid = newKid
            oldKid = child.sib
        }
        return newNode
    }

    /// Rewrite root key if in key table.
    private func rekeyKey(_ key: RecordKey?, keyTable: [RecordKey: RecordKey]) -> RecordKey? {
        guard let key else { return nil }
        return keyTable[key] ?? key
    }

    /// Rewrite node val if in key table.
    private func rekeyVal(_ val: String?, keyTable: [RecordKey: RecordKey]) -> String? {
        guard let val else { return nil }
        return keyTable[val] ?? val
    }
}

private func typeLetter(_ tag: String) -> String {
    return String(tag.first?.uppercased() ?? "X")
}

// Generate a random record key.
func generateRandomKey(index: RecordIndex) -> RecordKey {
    let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")

    for _ in 0..<10 {
        let randomChars = (0..<6).map { _ in alphabet.randomElement()! }
        let key = "@I" + String(randomChars) + "@"
        if index[key] == nil {
            return key
        }
    }
    fatalError("Unable to generate unique Record key.")
}
// VERSION FROM CHATGPT.
public func generateRandomKey(prefix: String, map: [String : String], length: Int = 8) -> RecordKey {
    let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")

    while true {
        let suffix = String((0..<length).map { _ in alphabet.randomElement()! })
        let key = "@\(prefix)\(suffix)@"
        if map[key] == nil {
            return key
        }
    }
}
