//
//  File.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 7/21/25.
//

func getValidRecordsFromPath(path: String, tagmap: inout TagMap, keymap: inout KeyMap, errlog: inout ErrorLog)
-> (index: RecordIndex, persons: RootList, families: RootList)? {

    let rootlist = getRecordsFromPath(path: path, tagmap: &tagmap, keymap: &keymap, errlog: &errlog)
    if errlog.count > 0 || rootlist == nil { return nil }
    checkKeysAndReferences(records: rootlist!, path: path, keymap: keymap, errlog: &errlog)
    if errlog.count > 0 { return nil }
    var index = RecordIndex()
    // Remove persons and families eventually.
    var persons = RootList()
    var	families = RootList()
    for root in rootlist! {
        if let key = root.key { index[key] = root }
        if root.tag == "INDI" { persons.append(root) }
        if root.tag == "FAM" { families.append(root) }
    }
    let context = ValidationContext(index: index, keymap: keymap, source: path)
    validatePersons(persons: persons, context: context, errlog: &errlog)
    //validateFamilies(families: families, context: context, errlog: &errlog)
    return (index, persons, families)
}

/// Returns the Gedcom records from a source. It uses getDataNodesFromPath and
/// buildRecords to create a RootList of records.
func oldgetRecordsFromPath(path: String, tagmap: inout TagMap, keymap: inout KeyMap,
                        errorlog: inout ErrorLog) -> RootList? {
    guard let dataNodes = getDataNodesFromPath(path: path, tagmap: &tagmap, keymap: &keymap, errlog: &errorlog)
    else { return nil }
    return getRecordsFromDataNodes(datanodes: dataNodes, keymap: keymap, errlog: &errorlog)
}

func getRecordsFromPath(
    path: String,
    tagmap: inout TagMap,
    keymap: inout KeyMap,
    errlog: inout ErrorLog
) -> RootList? {
    let source = FileGedcomSource(path: path)

    guard let dataNodes = getDataNodesFromSource(
        source: source,
        tagmap: &tagmap,
        keymap: &keymap,
        errlog: &errlog
    ) else {
        return nil
    }

    return getRecordsFromDataNodes(datanodes: dataNodes, keymap: keymap, errlog: &errlog)
}

/// Gets Gedcom records from a String.
public func getRecordsFromString(sourceText: String, tagmap: inout TagMap, keymap: inout KeyMap,
                                 errorlog: inout ErrorLog) -> RootList? {
    guard let dataNodes = getDataNodesFromString(sourceText: sourceText, tagmap: &tagmap, keymap: &keymap, errlog: &errorlog)
    else { return nil }
    return getRecordsFromDataNodes(datanodes: dataNodes, keymap: keymap, errlog: &errorlog)
}

func getDataNodesFromString(sourceText: String, tagmap: inout TagMap, keymap: inout KeyMap,
                            errlog: inout ErrorLog) -> DataNodes<Int>? {
    let lines = sourceText.components(separatedBy: .newlines)
    return getDataNodesFromLines(lines: lines, source: "<user-edit>", tagmap: &tagmap, keymap: &keymap, errlog: &errlog)
}

public func getDatabaseFromPath(_ path: String, errlog: inout ErrorLog) -> Database? {
    var keymap = KeyMap() // Maps record keys to the lines where defined.
    var tagmap = TagMap() // So there is only one copy of each tag.
    guard let (index, persons, families) = getValidRecordsFromPath(path: path, tagmap: &tagmap, keymap: &keymap,
                                                                   errlog: &errlog)
    else { return nil } // errlog holds the errors.
    let nameIndex = getNameIndex(persons: persons)
    //var refnIndex = getRefnIndex(persons: persons) // GET THIS WRITTEN!!
    return Database(recordIndex: index,
                    nameIndex: nameIndex, refnIndex: RefnIndex(), tagmap: tagmap)
}

func getDataNodesFromPath(path: String, tagmap: inout TagMap, keymap: inout KeyMap,
                          errlog: inout ErrorLog) -> DataNodes<Int>? {
    guard let fileContent = try? String(contentsOfFile: path, encoding: .utf8) else {
        errlog.append(Error(type: .system, severity: .fatal, message: "Failed to read file: \(path)"))
        return nil
    }
    let lines = fileContent.components(separatedBy: .newlines)
    return getDataNodesFromLines(lines: lines, source: path, tagmap: &tagmap, keymap: &keymap, errlog: &errlog)
}
