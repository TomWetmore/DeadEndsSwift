GEDCOM IMPORT

This document describes the "input stack" of DeadEnds when reading a Gedcom file.

##### getDataNodesFromPath(path: String, tagmap: inout TagMap, keymap: inout KeyMap, errlog: inout ErrorLog) -> DataNodes&lt;Int>?

This is the bottom of the stack. *getDataNodesFromPath* reads all the lines from a Gedcom file and returns them as a `DataNodes<Int>`, which is a list of `(GNode, Int)` tuples, where `Int` holds the levels of the nodes. It adds the location of each record to the keymap. Errors found are added to `errlog`. The source is fully processed regardless of errors. If there are errors `nil` is returned.

`path` is the name of the file; `tagmap` maps tags to unique strings; `keymap` maps the record keys found to root `GNode`s; and `errlog` is the error log.

func getDataNodesFromPath(path: String, tagmap: inout TagMap, keymap: inout KeyMap,

​						 errlog: inout ErrorLog) -> DataNodes<Int>? {

​	var nodes = DataNodes<Int>() // The [(node, level)] array to return.

​	var lineno = 0 // Source line number.

​	guard let fileContent = try? String(contentsOfFile: path, encoding: .utf8) else {

​		errlog.append(Error(type: .system, severity: .fatal, message: "Failed to read file: \(path)"))

​		return nil

​	}

​	let lines = fileContent.components(separatedBy: .newlines)

​	for line in lines {

​		lineno += 1

​		// Blank lines are okay though some Gedcom specs disallow them.

​		if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }

​		let readResult = extractFields(from: line) // Get level, key, tag, and value.

​		switch readResult {

​		case .success(level: let level, key: let key, tag: let tag, value: let value):

​			let node = Node(key: key, tag: tagmap.intern(tag: tag), value: value)

​			nodes.add(node: node, data: level)

​			if level == 0 && key != nil { keymap[key!] = lineno }

​		case .failure(errmsg: let errmsg):

​			let error = Error(type: .syntax, severity: .severe, source: path, line: lineno, message: "\(errmsg)")

​			errlog.append(error)

​		}

​	}

​	return nodes

}

**getRecordsFromDataNodes**

**getRecordsFromPath** returns the Gedcom records from a path. It uses getDataNodesFromPath and
// getRecordsFromDataNodes to create a RootList of records.
func getRecordsFromPath(path: String, tagmap: inout TagMap, keymap: inout KeyMap,
                        errorlog: inout ErrorLog) -> RootList? {
    guard let dataNodes = getDataNodesFromPath(path: path, tagmap: &tagmap, keymap: &keymap, errlog: &errorlog)
    else { return nil }
    return getRecordsFromDataNodes(datanodes: dataNodes, keymap: keymap, errlog: &errorlog)
}
