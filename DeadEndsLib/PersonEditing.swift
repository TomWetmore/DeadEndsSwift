//
//  PersonEditing.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 8/23/26.
//

import Foundation

public func oldgetPersonFromString(from string: String) -> (person: Person?, errlog: ErrorLog) {

    let (root, errlog) = loadRecordFromString(from: string)
    guard let root else {
        return (nil, errlog)
    }
    return (Person(root), errlog)
}

public func getPersonFromString(from string: String) -> (person: Person?, errlog: ErrorLog) {

    var (root, errlog) = loadRecordFromString(from: string)
    guard let root else {
        return (nil, errlog)
    }
    guard root.tag == GedcomTag.INDI, root.key != nil else {
        let error = DeadEndsError(type: .gedcom, severity: .severe,
                                  message: "Record is not a valid INDI record")
        errlog.append(error)
        return (nil, errlog)
    }
    return (Person(root), errlog)
}

public func getFamilyFromString(from string: String) -> (family: Family?, errlog: ErrorLog) {
    let (root, errlog) = loadRecordFromString(from: string)
    guard let root else {
        return (nil, errlog)
    }
    return (Family(root), errlog)
}
