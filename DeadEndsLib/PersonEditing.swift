//
//  PersonEditing.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 23 August 2026.
//  Last changed on 27 August 2026.
//

import Foundation

/// Try to extract a person record from a string.
public func getPersonFromString(from string: String) -> (person: Person?, errors: [String]) {

    let (root, errlog) = loadRecordFromString(from: string)  // Hard work done here.

    guard let root else {
        return (nil, errlog.map(\.description))
    }
    guard root.tag == GedcomTag.INDI, root.key != nil else {
        return (nil, ["1: Record is not a valid person"])
    }
    return (Person(root), [])
}

/// Want this to 1. Get Person from String; 2. Validate the changes; 3. Update the database.
func updatePerson(oldPerson: Person, newString: String, in database: Database) -> [String] {

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

    let policyErrors = validatePersonChanges(old: oldinfo, new: newinfo)
    if !policyErrors.isEmpty {
        return policyErrors
    }

    database.applyPersonUpdates(old: oldinfo, new: newinfo)
    return []
}

func validatePersonChanges(old: PersonInfo, new: PersonInfo) -> [String] {

    var errors: [String] = []

    if new.names.isEmpty {
        errors.append("Person must have at least one NAME line")
    }

    if new.sex == nil {
        errors.append("Person must have one SEX line")
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
        old.root.root.replaceChildren(with: new.root.kid)
    }
}

/// Structure holding Person information that is used when validating edit changes.
struct PersonInfo: CustomStringConvertible {

    let root: Person
    let key: String
    let sex: String?
    let names: Set<String>
    let famcKeys: Set<RecordKey>
    let famsKeys: Set<RecordKey>
    let dateKeys: Set<DateKey>
    let placeKeys: Set<PlaceKey>

    var description: String {
        "PersonInfo(root: key: \(key), sex: \(sex ?? "nil"), names: \(names) " +
            "famcKeys: \(famcKeys), famsKeys: \(famsKeys), dateKeys: \(dateKeys), " +
            "placeKeys: \(placeKeys))"
    }
}

/// Return the person info struct for a person; the person is not affected.
func getPersonInfo(for person: Person) -> (info: PersonInfo, errors: [String]) {

    var names: Set<String> = []
    var sex: String? = nil
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
            if let val = val {
                if sex == nil {
                    sex = val
                } else {
                    errors.append("\(line): Multiple SEX lines")
                }
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

    //  Build and re3turn the person info.
    let info = PersonInfo(root: person, key: person.key, sex: sex,
                          names: names, famcKeys: famcKeys, famsKeys: famsKeys,
                          dateKeys: dateKeys, placeKeys: placeKeys)
    return (info, errors)
}

