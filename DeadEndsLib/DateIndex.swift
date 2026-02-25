//
//  DateIndex.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 19 November 2025.
//  Last changed on 24 February 2026.
//

import Foundation

/// Date index key; combines year with event kind.
public struct DateIndexKey: Hashable {
    let year: Year
    let event: EventKind
}

/// Date index for DeadEnds database.
final public class DateIndex {

    private(set) var index: [DateIndexKey : Set<RecordKey>] = [:]  // Representation.

    /// Add entry to date index.
    func add(year: Year, event: EventKind, recordKey: RecordKey) {
        let dateKey = DateIndexKey(year: year, event: event)
        index[dateKey, default: Set()].insert(recordKey)
    }

    /// Remove entry from date index.
    func remove(year: Year, event: EventKind, recordKey: RecordKey) {
        let dateKey = DateIndexKey(year: year, event: event)
        if var records = index[dateKey] {
            records.remove(recordKey)
            if records.isEmpty { index.removeValue(forKey:dateKey) }
            else { index[dateKey] = records }
        }
    }

    /// Get the set of record keys for a year and event.
    public func recordKeys(year: Year, event: EventKind) -> Set<RecordKey>? {
        let dateIndexKey = DateIndexKey(year: year, event: event)
        return recordKeys(for: dateIndexKey)
    }

    /// Get the set of record keys for a date index key.
    public func recordKeys(for dateIndexKey: DateIndexKey) -> Set<RecordKey>? {
        return index[dateIndexKey]
    }

    /// Get the set of record keys for a year range and event.
    public func recordKeys(in range: ClosedRange<Year>, event: EventKind) -> Set<RecordKey> {
        var out = Set<RecordKey>()
        for year in range {
            if let keySet = recordKeys(year: year, event: event) {
                out.formUnion(keySet)
            }
        }
        return out
    }
}

/// Build date index for a record index.
public func buildDateIndex(from recordIndex: RecordIndex) -> DateIndex {
    let dateIndex = DateIndex()

    for (_, root) in recordIndex {
        switch root.tag {
        case GedcomTag.INDI:
            if let person = Person(root) { dateIndex.indexDates(from: person) }
        case GedcomTag.FAM:
            if let family = Family(root) { dateIndex.indexDates(from: family) }
        default: break
        }
    }
    return dateIndex
}

extension DateIndex {

    /// Index the date nodes in an event tree.
    private func indexDates(in eventNode: GedcomNode, kind: EventKind, recordKey: RecordKey) {
        for dateNode in eventNode.kids(withTag: GedcomTag.DATE) {
            guard let year = year(from: dateNode) else { continue }
            add(year: year, event: kind, recordKey: recordKey)
        }
    }

    /// Index the birth and death dates of a person.
    func indexDates(from person: Person) {
        guard let key = person.root.key else { return }
        for eventNode in person.root.kids where eventNode.hasTag(.birt) || eventNode.hasTag(.deat) {
            let kind: EventKind = eventNode.hasTag(.birt) ? .birth : .death
            indexDates(in: eventNode, kind: kind, recordKey: key)
        }
    }

    /// Index the marriage dates of a family.
    func indexDates(from family: Family) {
        guard let key = family.root.key else { return }
        for eventNode in family.root.kids where eventNode.hasTag(.marr) {
            indexDates(in: eventNode, kind: .marriage, recordKey: key)
        }
    }
}

/// Debugging aid.
extension DateIndex {

    /// Print contents of a date index.
    public func showContents(using recordIndex: RecordIndex) {
        let sortedEntries = index.sorted { $0.key.year < $1.key.year }
        for (dateKey, recordKeys) in sortedEntries {
            let event = dateKey.event.rawValue.capitalized
            let year  = dateKey.year
            for key in recordKeys.sorted() {
                if let person = recordIndex.person(for: key) {
                    print("\(event) \(year): \(person.displayName()) [\(key)]")
                } else if recordIndex.family(for: key) != nil {
                    print("\(event) \(year): Family \(key)")
                } else {
                    print("\(event) \(year): ??? (\(key))")
                }
            }
        }
    }
}
