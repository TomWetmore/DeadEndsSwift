//
//  PersonEditing.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 23 August 2026.
//  Last changed on 28 August 2026.
//

import Foundation

/// Attempt to update a person in the database with a modified version of the person.
/// The first version arrives as a person structure; the second version arrives as a
/// string. That string is parsed into new version of the person. The new version is
/// then checked to see if it can become a new version. If so the database is changed.
/// If updating is not possible, one or more error strings are returned that say why.
public func updatePerson(oldPerson: Person, newString: String, in database: Database) -> [String] {

    // Get a person by parsing the string.
    let results = getPersonFromString(from: newString)
    if results.errors.count > 0 {
        return results.errors
    }
    // Get person info for the two versions.
    let (oldinfo, _) = getPersonInfo(for: oldPerson)
    let newPerson = results.person!
    let (newinfo, errors) = getPersonInfo(for: newPerson)
    if errors.count > 0 {
        return errors
    }
    // See if there are any semantic errors in the new version.
    let policyErrors = validatePersonChanges(old: oldinfo, new: newinfo, in: database.recordIndex)
    if !policyErrors.isEmpty {
        return policyErrors
    }
    // There are no errors so update the database with new version of person.
    database.applyPersonUpdates(old: oldinfo, new: newinfo)
    return []
}

/// Try to extract a person record from a string.
func getPersonFromString(from string: String) -> (person: Person?, errors: [String]) {

    // loadRecordFromString does the hard work.
    let (root, errlog) = loadRecordFromString(from: string)

    guard let root else {
        return (nil, errlog.map(\.description))
    }
    guard root.tag == GedcomTag.INDI, root.key != nil else {
        return (nil, ["1: Record is not a valid person"])
    }
    return (Person(root), [])
}

/// Validate the person changes -- Make sure all changes are okay.
func validatePersonChanges(old: PersonInfo, new: PersonInfo, in index: RecordIndex) -> [String] {

    var errors: [String] = []

    if new.names.isEmpty {
        errors.append("Person must have at least one NAME line")
    }
    if new.sexCount != 1 {
        errors.append("Person must have exactly one SEX line")
    }
    if let sex = new.sex, !["M", "F", "U", "?"].contains(sex) {
        errors.append("SEX value must be M, F, U, or ?")
    }
    if new.famcKeys != old.famcKeys {
        errors.append("FAMC relationships cannot be added or removed")
    }
    if new.famsKeys != old.famsKeys {
        errors.append("FAMS relationships cannot be added or removed")
    }
    if new.key != old.key {
        errors.append("Person key cannot be changed")
    }

    for node in new.person.root.subnodes {
        guard let value = node.val, value.isKey else { continue }

        if index[value] == nil {
            let line = node.index + 1
            errors.append("\(line): Pointer to nonexistent record: \(value)")
        }
    }
    return errors
}

/// Update the database after successfully editing a person.
extension Database {

    func applyPersonUpdates(old: PersonInfo, new: PersonInfo) {

        let key = old.key

        // Update NameIndex
        let addedNames = new.names.subtracting(old.names)
        let removedNames = old.names.subtracting(new.names)
        for name in removedNames {
            nameIndex.remove(value: name, recordKey: key)
        }
        for name in addedNames {
            nameIndex.add(value: name, recordKey: key)
        }

        // Update date index.
        let addedDates = new.dateKeys.subtracting(old.dateKeys)
        let removedDates = old.dateKeys.subtracting(new.dateKeys)
        for dateKey in removedDates {
            dateIndex.remove(year: dateKey.year, event: dateKey.event, recordKey: key)
        }
        for dateKey in addedDates {
            dateIndex.add(year: dateKey.year, event: dateKey.event, recordKey: key)
        }

        // Update place index.
        let addedPlaces = new.placeKeys.subtracting(old.placeKeys)
        let removedPlaces = old.placeKeys.subtracting(new.placeKeys)
        for placeKey in removedPlaces {
            placeIndex.remove(part: placeKey.part, event: placeKey.event, recordKey: key)
        }
        for placeKey in addedPlaces {
            placeIndex.add(part: placeKey.part, event: placeKey.event, recordKey: key)
        }

        // Update the database with the edited person keeping the same Person root.
        old.person.root.replaceChildren(with: new.person.kid)
    }
}

/// Structure holding Person information that is used when validating.
struct PersonInfo: CustomStringConvertible {

    let person: Person
    let key: String
    let sex: String?
    let sexCount: Int
    let names: Set<String>
    let famcKeys: Set<RecordKey>
    let famsKeys: Set<RecordKey>
    let dateKeys: Set<DateKey>
    let placeKeys: Set<PlaceKey>

    var description: String {
        "PersonInfo(root: key: \(key), sex: \(sex ?? "nil"), sexCount: \(sexCount), " +
            "names: \(names) " +
            "famcKeys: \(famcKeys), famsKeys: \(famsKeys), dateKeys: \(dateKeys), " +
            "placeKeys: \(placeKeys))"
    }
}

/// Return the person info struct for a person; the person is not affected.
func getPersonInfo(for person: Person) -> (info: PersonInfo, errors: [String]) {

    var names: Set<String> = []
    var sex: String? = nil
    var sexCount = 0
    var famcKeys: Set<RecordKey> = []
    var famsKeys: Set<RecordKey> = []
    var dateKeys: Set<DateKey> = []
    var placeKeys: Set<PlaceKey> = []
    var errors: [String] = []

    var current = person.kid  // First level 1 node in person.
    while let node = current {  // Look at each level 1 node.

        let tag = node.tag
        let val = node.val
        let line = node.index + 1  // For error messages.

        switch tag {
        case "NAME":
            if let val = val {
                names.insert(val)
            } else {
                errors.append("\(line): Missing value for NAME line")
            }
        case "SEX":
            sexCount += 1
            if let val {
                if sex == nil {
                    sex = val
                }
            } else {
                errors.append("\(line): Missing value for SEX line")
            }
        case "FAMC":
            if let val = val {
                famcKeys.insert(val)
            } else {
                errors.append("\(line): Missing value for FAMC line")
            }
        case "FAMS":
            if let val = val {
                famsKeys.insert(val)
            } else {
                errors.append( "\(line): Missing value for FAMS line")
            }
        case "BIRT":
            for value in node.kidVals(forTag: "DATE") {
                guard let year = year(from: value) else { continue }
                dateKeys.insert(DateKey(year: year, event: .birth))
            }
            for value in node.kidVals(forTag: "PLAC") {
                for part in placeParts(value) {
                    placeKeys.insert(PlaceKey(part: part, event: .birth))
                }
            }
        case "DEAT":
            for value in node.kidVals(forTag: "DATE") {
                guard let year = year(from: value) else { continue }
                dateKeys.insert(DateKey(year: year, event: .death))
            }
            for value in node.kidVals(forTag: "PLAC") {
                for part in placeParts(value) {
                    placeKeys.insert(PlaceKey(part: part, event: .death))
                }
            }
        default: break
        }
        current = node.sib  // Next level 1 node.
    }

    //  Build and return the person info.
    let info = PersonInfo(person: person, key: person.key, sex: sex, sexCount: sexCount,
                          names: names, famcKeys: famcKeys, famsKeys: famsKeys,
                          dateKeys: dateKeys, placeKeys: placeKeys)
    return (info, errors)
}
