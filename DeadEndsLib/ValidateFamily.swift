//
//  ValidateFamily.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 2 January 2025.
//  Last changed 24 January 2026.
//

import Foundation

// validateFamilies validates the families in a RootList.
func validateFamilies(families: RecordList, index: RecordIndex, source: String, keymap: KeyMap,
					  errorlog: inout ErrorLog) {
	var numFamiliesValidated = 0
	for family in families {
		validateFamily(family: family, index: index, source: source, keymap: keymap, errlog: &errorlog)
		numFamiliesValidated += 1
	}
}

func validateFamily(family: GedcomNode, index: RecordIndex, source: String, keymap: KeyMap, errlog: inout ErrorLog) {

	if (family.key == nil) { fatalError("Family with no key.") }
	let fkey = family.key!
	let line = keymap[fkey]! // Location of family in the source.
	var errorCount = 0
	var husbKeys: Set<String> = []
	var wifeKeys: Set<String> = []
	var chilKeys: Set<String> = []
	var curnode = family.kid
	while let node = curnode {
		switch node.tag {
		case "HUSB":
			guard let pkey = node.val else {
				let errmsg = "Family \(fkey) has an illegal husband link"
				errlog.append(Error(type: .linkage, severity: .severe, source: source,
									line: line + node.offset(), message: errmsg))
				errorCount += 1
				break
			}
			guard !husbKeys.contains(pkey) else {
				let errmsg = "Family \(pkey) has duplicate husband link"
				errlog.append(Error(type: .linkage, severity: .severe, source: source,
									line: line + node.offset(), message: errmsg))
				errorCount += 1
				break
			}
			husbKeys.insert(fkey)
			guard let person = index[pkey] else {
				let errmsg = "Family \(fkey) has an illegal husband link"
				errlog.append(Error(type: .linkage, severity: .severe, source: source,
									line: line + node.offset(), message: errmsg))
				errorCount += 1
				break
			}
			if !person.hasFamilyAsChildLink(to: family) {
				let errmsg = "Family \(fkey) has husband link to \(pkey) that does not link back."
				errlog.append(Error(type: .linkage, severity: .severe, message: errmsg))
				errorCount += 1
				break
			}
		case "WIFE":
			guard let pkey = node.val else {
				let errmsg = "Family \(fkey) has an illegal wife link"
				errlog.append(Error(type: .linkage, severity: .severe, source: source,
									line: line + node.offset(), message: errmsg))
				errorCount += 1
				break
			}
			guard !wifeKeys.contains(pkey) else {
				let errmsg = "Family \(pkey) has duplicate wife link"
				errlog.append(Error(type: .linkage, severity: .severe, source: source,
									line: line + node.offset(), message: errmsg))
				errorCount += 1
				break
			}
			husbKeys.insert(fkey)
			guard let person = index[pkey] else {
				let errmsg = "Family \(fkey) has an illegal wife link"
				errlog.append(Error(type: .linkage, severity: .severe, source: source,
									line: line + node.offset(), message: errmsg))
				errorCount += 1
				break
			}
			if !person.hasFamilyAsChildLink(to: family) {
				let errmsg = "Family \(fkey) has wife link to \(pkey) that does not link back."
				errlog.append(Error(type: .linkage, severity: .severe, message: errmsg))
				errorCount += 1
				break
			}
			break
		case "CHIL":
			guard let pkey = node.val else {
				let errmsg = "Family \(fkey) has an illegal child link"
				errlog.append(Error(type: .linkage, severity: .severe, source: source,
									line: line + node.offset(), message: errmsg))
				errorCount += 1
				break
			}
			guard !husbKeys.contains(pkey) else {
				let errmsg = "Family \(pkey) has duplicate child link"
				errlog.append(Error(type: .linkage, severity: .severe, source: source,
									line: line + node.offset(), message: errmsg))
				errorCount += 1
				break
			}
			chilKeys.insert(fkey)
			guard let person = index[pkey] else {
				let errmsg = "Family \(fkey) has an illegal child link"
				errlog.append(Error(type: .linkage, severity: .severe, source: source,
									line: line + node.offset(), message: errmsg))
				errorCount += 1
				break
			}
			if !person.hasFamilyAsChildLink(to: family) {
				let errmsg = "Family \(fkey) has child link to \(pkey) that does not link back."
				errlog.append(Error(type: .linkage, severity: .severe, message: errmsg))
				errorCount += 1
				break
			}
			break
		default:
			break
		}
		curnode = node.sib
	}
}

// Extensions
extension GedcomNode {

	// 1. Self is the person who must have a FAMC or FAMS link to the family.
	// 2. Iterate the children of the person looking for a FAMC or FAMC link to the family key.

	// There is something common about all five of the has...Link methods. They should be
	// consolidated.
	// The consolidation should also include the code round in the validatePerson cases.

	// hasFamilyAsChildLink checks whether a person (self) has a FAMC link to the family.
	func hasFamilyAsChildLink(to family: GedcomNode) -> Bool {
		let person = self // self is a person root.
		var curnode = person.kid
		while let node = curnode {
			if node.tag == "FAMC" && node.val == family.key { return true }
			curnode = node.sib
		}
		return false
	}

	// hasFamilyAsSpouseLink checks whether a person (self) has a FAMS link to the family.
	func hasFamilyAsSpouseLink(to family: GedcomNode) -> Bool {
		let person = self // self is a person root.
		var curnode = person.kid
		while let node = curnode {
			if node.tag == "FAMS" && node.val == family.key { return true }
			curnode = node.sib
		}
		return false
	}
}
