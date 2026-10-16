//
//  Database.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 19 December 2024.
//  Last changed on 15 October 2026.
//

import Foundation

public typealias RecordKey = String
public typealias KeyMap = [RecordKey : Int]  // Maps keys to line numbers.
public typealias RootList = [Root]

/// A DeadEnds Database is composed of four in-memory indexes: a RecordIndex, NameIndex,
/// DateIndex, and Place Index. A Database is created by reading a Gedcom file and
/// creating a GedcomNode tree from each record in the file. The indexes are created from
/// those records. The Gedcom file is the persistant form of the Database.
///
final public class Database: CustomStringConvertible {

	public internal(set) var recordIndex: RecordIndex // Wrapped [RecordKey: Root]
	public private(set) var nameIndex: NameIndex   // Wrapped [NameKey: Set<RecordKey>]
    public private(set) var dateIndex: DateIndex   // Wrapped [DateKey : Set<RecordKey>]
    public private(set) var placeIndex: PlaceIndex // Wrapped [PlaceKey : Set<RecordKey>]
    public private(set) var persons: RootList = []
    public private(set) var families: RootList = []
    public private(set) var header: Root?  // Header record from Gedcom file.
    public private(set) var path: String?
    var dirty: Bool = false

    var personCount: Int { persons.count }
    var familyCount: Int { families.count }

    /// Description of database.
    ///
    public var description: String {
        var summary = "Database Summary:"
        summary += "\n    Number of keyed records: \(recordIndex.count)"
        summary += "\n    Number of persons: \(personCount)"
        summary += "\n    Number of families: \(familyCount)"
        summary += "\n    Header present: \(header != nil ? "Yes" : "No")"
        summary += "\n    Size of name index: \(nameIndex.count)"
        summary += "\n    Size of date index: \(dateIndex.count)"
        summary += "\n    Size of place index: \(placeIndex.count)"
        summary += "\n    Persons use \(size(of: persons)) nodes"
        summary += "\n    Families use \(size(of: families)) nodes"
        summary += "\n    Total size: \(size) nodes"
        return summary
    }

    /// Size of Database in GedcomNodes.
    ///
    var size: Int {
        recordIndex.values.reduce(0) { $0 + $1.count }
    }

    /// Size of a RootList in nodes. Maybe should be elsewhere.
    ///
    func size(of roots: RootList) -> Int {
        roots.reduce(0) { $0 + $1.count }
    }

    /// Create a Database from an array of validated records.
    ///
    init(records: RootList, path: String? = nil) {

        self.path = path
        recordIndex = RecordIndex()
        persons = RootList()
        families = RootList()
        header = nil
        for root in records {
            if let key = root.key {
                recordIndex[key] = root
            }
            if root.tag == "INDI" {
                persons.append(root)

            } else if root.tag == "FAM" {
                families.append(root)

            } else if root.tag == "HEAD" {
                header = root
            }
        }
        nameIndex = buildNameIndex(from: persons)
        dateIndex = buildDateIndex(from: recordIndex)
        placeIndex = buildPlaceIndex(from: recordIndex)
    }
}

extension Database {

    /// Return a new Database identical to self except that all keys are replaced with
    /// random values.
    ///
    public func rekeyDatabase() -> Database? {

        var rekeyMap: [RecordKey: RecordKey] = [:]  // Map from old to new keys.

        for (key, root) in recordIndex {  // Create the rekey map.
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

    /// Deep copy a GedcomNode tree, rewriting the keys and key references; recurse kids
    /// and iterate sibs.
    ///
    private func copyTreeRekeying(_ node: GedcomNode, keyTable: [RecordKey: RecordKey])
                                                -> GedcomNode {
                                                    
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
        guard let key else {
            return nil
        }
        return keyTable[key] ?? key
    }

    /// Rewrite node val if in key table.
    private func rekeyVal(_ val: String?, keyTable: [RecordKey: RecordKey]) -> String? {
        guard let val else {
            return nil
        }
        return keyTable[val] ?? val
    }
}

private func typeLetter(_ tag: String) -> String {

    return String(tag.first?.uppercased() ?? "X")
}

/// Generate a random RecordKey using Gedcom rules.
///
public func generateRandomKey(prefix: String, map: [String : String],
                              length: Int = 8) -> RecordKey {

    let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")

    while true {  // Loop until unique key is generated.
        let suffix = String((0..<length).map { _ in alphabet.randomElement()! })
        let key = "@\(prefix)\(suffix)@"
        if map[key] == nil { return key }
    }
}

extension Database {

    /// Write a database to a file system path.
    func write(to path: String) {
         //write HEAD if present or synthesize one
         //write all keyed records in some chosen order
         //write TRLR
         //atomically write the file
    }
}

