//
//  ImportStack.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 12/19/24.
//  Last changed on 1/27/25.
//

import Foundation

// Validation Context reduces the number of parameters for some of the functions.
struct ValidationContext {
	let index: RecordIndex
	let keymap: KeyMap
	let source: String

	init(index: RecordIndex, keymap: KeyMap, source: String) {
		self.index = index
		self.keymap = keymap
		self.source = source
	}
}

// getValidRecordsFromPath reads a Gedcom file into the main database containers. If keymap is nil one is created.
func getValidRecordsFromPath(path: String, tagmap: inout TagMap, keymap: inout KeyMap, errlog: inout ErrorLog)
		-> (index: RecordIndex, persons: RootList, families: RootList)? {

	let rootlist = getRecordsFromPath(path: path, tagmap: &tagmap, keymap: &keymap, errorlog: &errlog)
	if errlog.count > 0 || rootlist == nil { return nil }
	checkKeysAndReferences(records: rootlist!, path: path, keymap: keymap, errlog: &errlog)
	if errlog.count > 0 { return nil }
	var index = RecordIndex()
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

// getRecordsFromPath returns the Gedcom records from a source. It uses getDataNodesFromPath and
// getRecordsFromDataNodes to create a RootList of records.
func getRecordsFromPath(path: String, tagmap: inout TagMap, keymap: inout KeyMap,
						errorlog: inout ErrorLog) -> RootList? {
	guard let dataNodes = getDataNodesFromPath(path: path, tagmap: &tagmap, keymap: &keymap, errlog: &errorlog)
	else { return nil }
	return getRecordsFromDataNodes(datanodes: dataNodes, keymap: keymap, errlog: &errorlog)
}

// getDataNodesFromPath returns all lines from a Gedcom source as a [DataNodes<Int>], where the Int field holds the
// levels of the nodes. It adds the location of each record to the keymap. Errors found are added to errlog. The source
// is fully processed regardless of errors. If there are errors nil is returned.
func getDataNodesFromPath(path: String, tagmap: inout TagMap, keymap: inout KeyMap,
						  errlog: inout ErrorLog) -> DataNodes<Int>? {
	var nodes = DataNodes<Int>() // The [(node, level)] array to return.
	var lineno = 0 // Source line number.
	guard let fileContent = try? String(contentsOfFile: path, encoding: .utf8) else {
		errlog.append(Error(type: .system, severity: .fatal, message: "Failed to read file: \(path)"))
		return nil
	}
	let lines = fileContent.components(separatedBy: .newlines)
	for line in lines {
		lineno += 1
		// Blank lines are okay though some Gedcom specs disallow them.
		if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
		let readResult = extractFields(from: line) // Get level, key, tag, and value.
		switch readResult {
		case .success(level: let level, key: let key, tag: let tag, value: let value):
			let node = GedcomNode(key: key, tag: tagmap.intern(tag: tag), value: value)
			nodes.add(node: node, data: level)
			if level == 0 && key != nil { keymap[key!] = lineno }
		case .failure(errmsg: let errmsg):
			let error = Error(type: .syntax, severity: .severe, source: path, line: lineno, message: "\(errmsg)")
			errlog.append(error)
		}
	}
	return nodes
}

// getRecordsFromDataNodes processes an Array of (Node, level) pairs from a Gedcom source into an Array of Node
// trees (aka Records). It requires the levels to guide the tree building.
func getRecordsFromDataNodes(datanodes: DataNodes<Int>, keymap: KeyMap, errlog: inout ErrorLog) -> RootList {
	enum State { case initial, main, error } // Tree building done by state machine.
	var state: State = .initial
	var rootList = RootList() // Array of roots of the constructed Node trees.
	var pnode: GedcomNode? = nil // Previous Node.
	var plevel = 0 // Previous level.
	var rnode: GedcomNode? = nil // Current root.

	for (node, level) in datanodes {
		switch state {
		case .initial: // Handle first pair; level must be 0).
			if (level == 0) {
				rnode = node; // Set current root and enter .main state.
				state = .main;
			} else { // Issue error and enter .error state.
				let error = Error(type: .syntax, severity: .fatal, message: "First line must have level 0")
				errlog.append(error)
				state = .error
			}
		case .main: // Builds Node trees from the (Node, level)'s.
			if (level == 0) { // Found next root.
				rootList.append(rnode!) // Save current Node tree.
				rnode = node; // Set current root of the next tree.
			} else if (level == plevel) { // Found the sibling of previous Node.
				node.parent = pnode!.parent;
				pnode!.nextSibling = node
			} else if (level == plevel + 1) { // Found the child of previous Node.
				node.parent = pnode
				pnode!.firstChild = node
			} else if (level < plevel) { // Found an uncle of previous Node.
				var count = 0;
				while (level < plevel) {
					count += 1
					if (count > 100 || pnode == nil) { // Cycle in tree?
						let error = Error(type: .syntax, severity: .fatal,
										  message: "Too many ancestors: mis-formed tree?")
						errlog.append(error)
						state = .error
						break
					}
					pnode = pnode!.parent
					plevel -= 1;
				}
				node.parent = pnode!.parent
				pnode!.nextSibling = node
			} else { // level > plevel + 1 is illegal
				let error = Error(type: .syntax, severity: .fatal, message: "Invalid level")
				errlog.append(error)
				state = .error
			}
		case .error: // Skip Nodes until the next 0 level.
			if level == 0 {
				state = .main
			}
		}
		plevel = level
		pnode = node
	}
	if (state == .main) { // If in .main state at end save the last Node tree.
		rootList.append(rnode!)
	}
	return rootList;
}

// ReadResult is the type returned by extractFields.
enum ReadResult {
	case success(level: Int, key: String?, tag: String, value: String?)
	case failure(errmsg: String)
}

// extractFields extracts the level, key, tag and value from a string holding a single Gedcom line.
func extractFields(from line: String) -> ReadResult {
	let trim = line.trimmingCharacters(in: .whitespacesAndNewlines)

	guard !trim.isEmpty else { return .failure(errmsg: "Empty string") }
	guard trim.count <= 255 else { return .failure(errmsg: "Gedcom line is too long") }
	var index = trim.startIndex

	// Get level.
	while index < trim.endIndex, trim[index].isWhitespace { index = trim.index(after: index) } // Skip whitespace.
	guard index < trim.endIndex, trim[index].isNumber else { return .failure(errmsg: "Line does not begin with level") }
	var levelString = ""
	while index < trim.endIndex, trim[index].isNumber {
		levelString.append(trim[index])
		index = trim.index(after: index)
	}
	guard let level = Int(levelString) else { return .failure(errmsg: "Invalid level") }

	// Get key if present.
	while index < trim.endIndex, trim[index].isWhitespace { index = trim.index(after: index) } // Skip whitespace.
	if index >= trim.endIndex { return .failure(errmsg: "Gedcom line is incomplete") }
	var key: String? = nil
	if trim[index] == "@" {
		let keyStart = index
		index = trim.index(after: index)
		guard index < trim.endIndex, trim[index] != "@" else { return .failure(errmsg: "Illegal key (@@)") }
		while index < trim.endIndex, trim[index] != "@" {
			index = trim.index(after: index)
		}
		guard index < trim.endIndex else { return .failure(errmsg: "Gedcom line is incomplete") }
		index = trim.index(after: index) // Skip closing '@'
		guard index < trim.endIndex, trim[index].isWhitespace else {
			return .failure(errmsg: "There must be a space between the key and tag")
		}
		key = String(trim[keyStart..<index])
		index = trim.index(after: index) // Skip the space
	}
	while index < trim.endIndex, trim[index].isWhitespace { index = trim.index(after: index) } // Skip whitespace.
	guard index < trim.endIndex else { return .failure(errmsg: "The line is incomplete") }

	// Get tag.
	let tagStart = index
	while index < trim.endIndex, !trim[index].isWhitespace { index = trim.index(after: index) }
	let tag = String(trim[tagStart..<index])
	while index < trim.endIndex, trim[index].isWhitespace { index = trim.index(after: index) }

	// Get value if present
	let value = index < trim.endIndex ? String(trim[index...]) : nil

	return .success(level: level, key: key, tag: tag, value: value)
}
