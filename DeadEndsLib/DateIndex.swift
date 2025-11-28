//
//  DateIndex.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 19 November 2025.
//  Last changed on 22 November 2025.
//

import Foundation

/// Provides the DateIndex feature on a Database.
final public class DateIndex {
    private(set) var index: [DateIndexKey : Set<RecordKey>] = [:]

    /// Adds an entry to the DateIndex.
    func add(year: Year, event: EventType, recordKey: RecordKey) {
        let dateKey = DateIndexKey(event: event, year: year)
        index[dateKey, default: Set()].insert(recordKey)
    }

    /// Removes an entry from the DateIndex.
    func remove(year: Year, event: EventType, recordKey: RecordKey) {
        let dateKey = DateIndexKey(event: event, year: year)
        if var records = index[dateKey] {
            records.remove(recordKey)
            if records.isEmpty { index.removeValue(forKey:dateKey) }
            else { index[dateKey] = records }
        }
    }

    /// Gets the Set of RecordKeys for a DateKey.
    func keys(year: Year, event: EventType) -> Set<RecordKey>? {
        let dateKey = DateIndexKey(event: event, year: year)
        return index[dateKey]
    }
}

struct DateIndexKey: Hashable {
    let event: EventType   // birth, death, marriage, ...
    let year: Year
}

enum EventType: String, Hashable {
    case birth  // Maps to Sets of Person keys.
    case marriage  // Maps to Sets of Family keys.
    case death  // Maps to Sets of Person Keys
    case other  // For all other Person events.
}

/// Builds a DateIndex for the Records in a RecordIndex.
public func buildDateIndex(from recordIndex: RecordIndex) -> DateIndex {
    let dateIndex = DateIndex()

    for (_, root) in recordIndex {
        switch root.tag {
        case "INDI":
            if let person = Person(root) { datesFromPerson(person: person, dateIndex: dateIndex) }

        case "FAM" :
            if let family = Family(root) { datesFromFamily(family: family, dateIndex: dateIndex) }

        default: break  // For now extract only from Persons and Families.
        }
    }
    return dateIndex
}

/// Indexes the birth and death dates in a Person's record.
func datesFromPerson(person: Person, dateIndex: DateIndex) {
    guard let key = person.root.key else { return }

    for node in person.root.kids where node.tag == "BIRT" || node.tag == "DEAT" {
        let eventType: EventType = (node.tag == "BIRT") ? .birth : .death
        for dateNode in node.kids(withTag: "DATE") {  // Allow more than 2 DATE nodes per event.
            guard let string = year(from: dateNode), let year = Int(string)
            else { continue }
            dateIndex.add(year: year, event: eventType, recordKey: key)
        }
    }
}

/// Indexes the marriage dates in a Family's record.
func datesFromFamily(family: Family, dateIndex: DateIndex) {
    guard let key = family.root.key else { return }

    for node in family.root.kids where node.tag == "MARR" {
        for dateNode in node.kids(withTag: "DATE") {  // Allow more than 2 DATE nodes per event.
            guard let string = year(from: dateNode), let year = Int(string)
            else { continue }
            dateIndex.add(year: year, event: .marriage, recordKey: key)
        }
    }
}

/// Debugging aids.
extension DateIndex {

    /// Debug method that prints the contents of a DateIndex.
    func showContents(using recordIndex: RecordIndex) {
        let sortedEntries = index.sorted { $0.key.year < $1.key.year }
        for (dateKey, recordKeys) in sortedEntries {
            let event = dateKey.event.rawValue.capitalized
            let year  = dateKey.year
            for key in recordKeys.sorted() {
                if let person = recordIndex.person(for: key) {
                    print("\(event) \(year): \(person.displayName()) [\(key)]")
                }
                else if recordIndex.family(for: key) != nil {
                    print("\(event) \(year): Family \(key)")
                }
                else {
                    print("\(event) \(year): ??? (\(key))")
                }
            }
        }
    }
}

