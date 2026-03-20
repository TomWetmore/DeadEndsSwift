//
//  Database.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 19 December 2024.
//  Last changed on 16 March 2026.
//

import Foundation

public typealias RecordKey = String
public typealias KeyMap = [RecordKey : Int]  // Keys to line numbers.
public typealias RootList = [Root]

/// DeadEnds in-RAM database.
final public class Database: CustomStringConvertible {

	public internal(set) var recordIndex: RecordIndex
    public private(set) var header: Root?
    public private(set) var persons: RootList = []
    public private(set) var families: RootList = []
	public private(set) var nameIndex: NameIndex
    public private(set) var dateIndex: DateIndex
    public private(set) var placeIndex: PlaceIndex
	public private(set) var refnIndex: RefnIndex
    public private(set) var path: String?
    var dirty: Bool = false

    var personCount: Int { persons.count }
    var familyCount: Int { families.count }

    /// Description of database.
    public var description: String {
        var summary = "Database Summary:"
        summary += "\n    Length of index: \(recordIndex.count)"
        summary += "\n    Number of persons: \(personCount)"
        summary += "\n    Number of families: \(familyCount)"
        summary += "\n    Header present: \(header != nil ? "Yes" : "No")"
        summary += "\n    Size of name index: \(nameIndex.count)"
        summary += "\n    Size of data index: \(dateIndex.count)"
        summary += "\n    Size of place index: \(placeIndex.count)"
        summary += "\n    Size of refn index: \(refnIndex.count)"
        summary += "\n    Persons use \(size(of: persons)) nodes"
        summary += "\n    Families use \(size(of: families)) nodes"
        summary += "\n    Total size: \(size) nodes"
        return summary
    }

    /// Size of database in nodes.
    var size: Int {
        recordIndex.values.reduce(0) { $0 + $1.count }
    }

    /// Size of a record list in nodes. Maybe should be elsewhere.
    func size(of roots: RootList) -> Int {
        roots.reduce(0) { $0 + $1.count }
    }

    /// Create database from array of validated records.
    init(records: RootList, path: String? = nil) {
        self.path = path
        recordIndex = RecordIndex()
        persons = RootList()
        families = RootList()
        header = nil
        for root in records {
            if let key = root.key { recordIndex[key] = root }
            if root.tag == GedcomTag.INDI { persons.append(root) }
            else if root.tag == GedcomTag.FAM { families.append(root) }
            else if root.tag == GedcomTag.HEAD { header = root }
        }
        nameIndex = buildNameIndex(from: persons)
        dateIndex = buildDateIndex(from: recordIndex)
        placeIndex = buildPlaceIndex(from: recordIndex)
        refnIndex = buildRefnIndex(from: recordIndex)
    }
}

/// Load database from Gedcom file; if errors no database is created.
public func loadDatabase(from path: String, errlog: inout ErrorLog) -> Database? {
    loadDatabase(from: FileGedcomSource(path: path), path: path, errLog: &errlog)
}

/// Load database from source; keyMap used for error messages.
private func loadDatabase(from source: GedcomSource, path: String? = nil,
                          errLog: inout ErrorLog) -> Database? {
    var keyMap = KeyMap()
    guard let roots = loadValidRecords(from: source, keyMap: &keyMap, errlog: &errLog)
    else { return nil }
    return Database(records: roots, path: path)
}

extension Database {

    /// Return new database with random record keys and key references.
    public func rekeyDatabase() -> Database? {
        var rekeyMap: [RecordKey: RecordKey] = [:]  // Old key to new key map.

        for (key, root) in recordIndex {  // Create old to new key map.
            rekeyMap[key] = generateRandomKey(prefix: typeLetter(root.tag), map: rekeyMap)
        }
        var newRoots: [Root] = []
        newRoots.reserveCapacity(recordIndex.count)
        for (_, root) in recordIndex {  // Deep copy records, rewriting keys and references.
            let newRoot = copyTreeRekeying(root, keyTable: rekeyMap)
            newRoots.append(newRoot)
        }
        return Database(records: newRoots)  // Return new database.
    }

    /// Deep copy Gedcom tree rewriting keys and key refs; recurse kids but iterate sibs.
    private func copyTreeRekeying(_ node: GedcomNode, keyTable: [RecordKey: RecordKey]) -> GedcomNode {
        let newNode = GedcomNode(key: rekeyKey(node.key, keyTable: keyTable), tag: node.tag,
                                 val: rekeyVal(node.val, keyTable: keyTable))
        var oldKid = node.kid
        var prevNewKid: Root? = nil
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

extension Database {

    func write(to path: String) {
         //flatten the database into top-level records
         //write HEAD if present or synthesize one
         //write all keyed records in chosen order
         //write TRLR
         //atomically write the file
    }
}

