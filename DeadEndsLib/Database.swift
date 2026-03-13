//
//  Database.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 19 December 2024.
//  Last changed on 12 March 2026.
//

import Foundation

public typealias RecordKey = String
public typealias RecordIndex = [RecordKey: Root]
public typealias KeyMap = [RecordKey : Int]  // Keys to line numbers.
public typealias RootList = [Root]

/// DeadEnds in-RAM database.
final public class Database {

	public internal(set) var recordIndex: RecordIndex
    public private(set) var header: GedcomNode?
    public private(set) var persons: RootList = []
    public private(set) var families: RootList = []
	public var nameIndex: NameIndex
    public var dateIndex: DateIndex
    public var placeIndex: PlaceIndex
	public var refnIndex: RefnIndex
    var dirty: Bool = false

    var personCount: Int { persons.count }
    var familyCount: Int { families.count }

    /// Create database from array of validated records.
    init(records: RootList) {
        recordIndex = [:]
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
        refnIndex = RefnIndex()  // TODO: Awaiting change to the index.
    }
}

/// Load database from Gedcom file; if errors no database is created.
public func loadDatabase(from path: String, errlog: inout ErrorLog) -> Database? {
    loadDatabase(from: FileGedcomSource(path: path), errLog: &errlog)
}

/// Load database from source; keyMap used for error messages.
private func loadDatabase(from source: GedcomSource, errLog: inout ErrorLog) -> Database? {
    var keyMap = KeyMap()  // Map keys to lines.
    guard let roots = loadValidRecords(from: source, keyMap: &keyMap, errlog: &errLog)
    else { return nil }
    return Database(records: roots)
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
        let newRoots = recordIndex.values.map {
            copyTreeRekeying($0, keyTable: rekeyMap)
        }
        return RecordIndex(
            uniqueKeysWithValues: newRoots.map { ($0.key!, $0) }
        )
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
