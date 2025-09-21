//
//  ValidatePerson.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 23 December 2024.
//  Last changed on 14 July 2025.
//

import Foundation

typealias StringSet = Set<String>

// validatePersons validates the persons in a RootList.
func validatePersons(persons: RecordList, context: ValidationContext, errlog: inout ErrorLog) {
	var numPersonsValidated = 0 // Debugging.
	for person in persons {
		person.validatePerson(context: context, errlog: &errlog)
		numPersonsValidated += 1
	}
}

// Methods on Persons.
extension GedcomNode {

	// validatePerson is a method that validates a Person. index is a record index; source is the the Gedcom source;
	// keymap maps record keys to lines in the source; and errlog is the error log.
	func validatePerson(context: ValidationContext, errlog: inout ErrorLog) {
		let person = self
		var hasName = false
		var hasSex = false
		var sexLines = 0
		let pkey = person.key! // Person's key.
		let line = context.keymap[pkey]! // Location of person in source.
		let source = context.source
		var famKeys = StringSet() // Family keys found on FAMC and FAMS nodes.

		// Validate NAME and SEX Nodes.
		person.traverseChildren { node in
			switch node.tag {
			case "NAME":
				if let value = node.val, !value.isEmpty {
					hasName = true
				} else {
					errlog.append(Error(type: .validate, severity: .severe, line: line + node.offset(),
										message: "Person \(pkey) has an empty NAME line."))
				}
			case "SEX":
				sexLines += 1
				if let value = node.val, ["M", "F", "U"].contains(value) {
					hasSex = true
				} else {
					errlog.append(Error(type: .validate, severity: .severe, line: line + node.offset(),
										  message: "Person \(pkey) has an invalid SEX line."))
				}
			default:
				break
			}
		}

		if !hasName {
			errlog.append(Error(type: .validate, severity: .severe, source: source, line: line,
								message: "Person \(pkey) is missing a NAME line."))
		}
		if !hasSex {
			errlog.append(Error(type: .validate, severity: .severe, source: source, line: line,
								message: "Person \(pkey) is missing a SEX line."))
		} else if sexLines != 1 {
			errlog.append(Error(type: .validate, severity: .severe, source: source, line: line,
								message: "Person \(pkey) has more than one SEX line."))
		}

		// Validate FAMC and FAMS Nodes.
		person.traverseChildren { node in
			switch node.tag {
			case "FAMC":
				node.validateFamilyLink(person: person, role: .child, seenkeys: &famKeys,
										context: context, line: line, errlog: &errlog)
			case "FAMS":
				node.validateFamilyLink(person: person, role: .spouse, seenkeys: &famKeys,
										context: context, line: line, errlog: &errlog)
			default:
				break
			}
		}
	}
}

extension GedcomNode { // Extension for internal Nodes.

	// validateFamilyLink is a method called on FAMC and FAMS nodes in persons. It checks the values of the nodes
	// to be sure they refer to valid families. It further checks that the families have the proper return links
	// to the node's person record.
	// Parameters:  personKey is the key of node's person record; role specifies whether the node is a FAMC or FAMS;
	// seenkeys is the set of family keys that have been
	// seen for the person; index is the full record index; source is the record source; line is the location of the
	// person in the source; and errlog is the error log.
	private func validateFamilyLink(person: GedcomNode, role: FamilyRole, seenkeys: inout StringSet,
									context: ValidationContext, line: Int, errlog: inout ErrorLog) {
		let pkey = person.key! // Must succeed
		guard let fkey = self.val else { // The node must have a value.
			appendError(errlog: &errlog, type: .linkage, source: context.source, line: line + self.offset(),
						message: "Person \(pkey) has an illegal \(role.rawValue) value")
			return
		}
		guard !seenkeys.contains(fkey) else { // The value of the node must not have been seen before.
			appendError(errlog: &errlog, type: .linkage, source: context.source, line: line + self.offset(),
						message: "Person \(pkey) has duplicate \(role.rawValue) value")
			return
		}
		seenkeys.insert(fkey)
		guard let family = context.index[fkey] else { // The family referred to by the node must exist.
			appendError(errlog: &errlog, type: .linkage, source: context.source, line: line + self.offset(),
						message: "Person \(pkey) has an illegal \(role.rawValue) link")
			return
		}
		if !family.validateReciprocalLink(to: pkey, for: role, source: context.source, errlog: &errlog) {
			return
		}
	}
}

private func appendError(errlog: inout ErrorLog, type: ErrorType, source: String, line: Int = 0, message: String) {
	errlog.append(Error(type: type, severity: .severe, source: source, line: line, message: message))
}

enum FamilyRole: String {
	case child = "FAMC"
	case spouse = "FAMS"
}

enum PersonRole: String {
	case husband = "HUSB"
	case wife = "WIFE"
	case child = "CHILD"
}

// Methods on nodes at any level
extension GedcomNode {

	// traverseChildren is a method that traverses all children of a node and performs an action on each.
//	func traverseChildren(action: (Node) -> Void) {
//		var currentNode = self.firstChild
//		while let node = currentNode {
//			action(node)
//			currentNode = node.nextSibling
//		}
//	}
//
//	// traverseChildrenBool traverses the children of a Node performing a Boolean action, ending
//	// the loop if the action returns true.
//	func traverseChildrenBool(action: (Node) -> Bool) {
//		var current = self.firstChild
//		while let child = current {
//			if action(child) { return }
//			current = child.nextSibling
//		}
//	}
}

// Methods on families.
extension GedcomNode {

	func validateReciprocalLink(to personKey: String, for type: FamilyRole, source: String,
								errlog: inout ErrorLog) -> Bool {
		switch type {
		case .child: // Family should have a CHIL link to person with personKey.
			if !self.hasChildLink(to: personKey) {
				let message = "Family \(self.key ?? "unknown") has no CHIL link back to person \(personKey)."
				appendError(errlog: &errlog, type: .linkage, source: source, message: message)
				return false
			}
		case .spouse: // Family should have a HUSB or WIFE link to person with personKey.
			if !self.hasSpouseLink(to: personKey) {
				let message = "Family \(self.key ?? "unknown") has no spouse link back to person \(personKey)."
				appendError(errlog: &errlog, type: .linkage, source: source, message: message)
				return false
			}
		}
		return true
	}

	// self is a person Node.
	func validateLink(to familyKey: String, for type: PersonRole, source: String, line: Int, errlog: inout ErrorLog) {
		switch type {
		case .husband:
			break
		case .wife:
			break
		case .child:
			break
		}
	}

	// hasChildLink is a method that checks whether a family has a child link to a person.
	func hasChildLink(to personKey: String) -> Bool {
		var found = false
		traverseChildren { node in
			if node.tag == "CHIL" && node.val == personKey {
				found = true
			}
		}
		return found
	}
	func hasSpouseLink(to personKey: String) -> Bool {
		var found = false
		traverseChildren { node in
			if node.tag == "HUSB" || node.tag == "WIFE", node.val == personKey {
				found = true
			}
		}
		return found
	}
}
// END FROM CHAT

// validatePerson validates a person. Persons must have at least one NAME and one SEX line with
// valid values. All FAMC and FAMS links must link to families that link back to the person.
//func oldValidatePerson(person: Node, index: RecordIndex, source: String, keymap: KeyMap,
//					errlog: inout ErrorLog) {
//	var errorCount = 0
//	var hasValidName = false
//	var hasValidSex = false
//	var numsexlines = 0
//	if (person.key == nil) { fatalError("Person with no key encountered.") }
//	let pkey = person.key!
//	let line = keymap[pkey]! // Location of person in its source.
//
//	// Pass one: validate NAME and SEX nodes.
//	var curnode = person.firstChild
//	while let node = curnode {
//		switch node.tag {
//		case "NAME":
//			if let value = node.value, !value.isEmpty {
//				hasValidName = true
//			} else {
//				let errorMessage = "INDI \(pkey) has an empty NAME line."
//				let offset = line + node.offset()
//				errlog.append(Error(type: .validate, severity: .severe, line: offset,
//									  message: errorMessage))
//				errorCount += 1
//			}
//		case "SEX":
//			numsexlines += 1
//			if let value = node.value, ["M", "F", "U"].contains(value) {
//				hasValidSex = true
//			} else {
//				let errorMessage = "INDI \(pkey) has an invalid SEX line."
//				let line = keymap[pkey]! + node.offset()
//				errlog.append(Error(type: .validate, severity: .severe, line: line,
//									  message: errorMessage))
//				errorCount += 1
//			}
//		default:
//			break
//		}
//		curnode = node.nextSibling
//	}
//	if !hasValidName {
//		let errorMessage = "INDI \(pkey) is missing a NAME line."
//		errlog.append(Error(type: .validate, severity: .severe, message: errorMessage))
//		errorCount += 1
//	}
//	if !hasValidSex {
//		let errorMessage = "INDI \(pkey) is missing a SEX line."
//		errlog.append(Error(type: .validate, severity: .severe, message: errorMessage))
//		errorCount += 1
//	} else if numsexlines != 1 {
//		let errmsg = "INDI \(pkey) has more than one SEX line."
//		errlog.append(Error(type: .validate, severity: .severe, source: source, line: line, message: errmsg))
//	}
//
//	// Pass two: validate FAMC and FAMS links
//	var famcKeys: Set<String> = []
//	var famsKeys: Set<String> = []
//	curnode = person.firstChild
//	while let node = curnode {
//		switch node.tag {
//		case "FAMC":
//			guard let fkey = node.value else {
//				let errmsg = "INDI \(pkey) has an illegal FAMC link"
//				errlog.append(Error(type: .linkage, severity: .severe, source: source,
//									line: line + node.offset(), message: errmsg))
//				errorCount += 1
//				break
//			}
//			guard !famcKeys.contains(fkey) else {
//				let errmsg = "INDI \(pkey) has duplicate FAMC link"
//				errlog.append(Error(type: .linkage, severity: .severe, source: source,
//									line: line + node.offset(), message: errmsg))
//				errorCount += 1
//				break
//			}
//			famcKeys.insert(fkey)
//			guard let family = index[fkey] else {
//				let errmsg = "INDI \(pkey) has an illegal FAMC link"
//				errlog.append(Error(type: .linkage, severity: .severe, source: source,
//									line: line + node.offset(), message: errmsg))
//				errorCount += 1
//				break
//			}
//			if !family.hasChildLink(to: person) {
//				let errmsg = "INDI \(pkey) has FAMC link to \(fkey) that does not link back as child."
//				errlog.append(Error(type: .linkage, severity: .severe, message: errmsg))
//				errorCount += 1
//				break
//			}
//		case "FAMS":
//			guard let fkey = node.value else {
//				let errmsg = "INDI \(pkey) has an illegal FAMS link"
//				errlog.append(Error(type: .linkage, severity: .severe, source: source,
//									  line: line + node.offset(), message: errmsg))
//				errorCount += 1
//				break
//			}
//			guard !famsKeys.contains(fkey) else {
//				let errmsg = "INDI \(pkey) has duplicate FAMS link"
//				errlog.append(Error(type: .linkage, severity: .severe, source: source,
//									line: line + node.offset(), message: errmsg))
//				errorCount += 1
//				break
//			}
//			famsKeys.insert(fkey)
//			guard let family = index[fkey] else {
//				let errmsg = "INDI \(pkey) has an illegal FAMS link"
//				errlog.append(Error(type: .linkage, severity: .severe, source: source,
//									line: line + node.offset(), message: errmsg))
//				errorCount += 1
//				break
//			}
//			if !family.hasSpouseLink(to: person) {
//				let errmsg = "INDI \(pkey) has FAMS link to \(fkey) that does not link back as spouse."
//				errlog.append(Error(type: .linkage, severity: .severe, source: source,
//									line: line + node.offset(), message: errmsg))
//				errorCount += 1
//				break
//			}
//			break
//		default:
//			break
//		}
//		curnode = node.nextSibling
//	}
//	return
//}

// Extensions and Helpers
extension GedcomNode {

	// hasChildLink checks whether the family (self) has a CHIL link to the person.
	func orighasChildLink(to person: GedcomNode) -> Bool {
		let family = self // self is a family root.
		var curnode = family.kid
		while let node = curnode {
			if node.tag == "CHIL" && node.val == person.key { return true }
			curnode = node.sib
		}
		return false
	}

	// hasSpouseLine checks whether the family (self) has a proper HUSB or WIFE link to the person.
	func hasSpouseLink(to person: GedcomNode) -> Bool {
		let family = self // self is a family root.
		let sex = person.getSex()
		guard sex != .unknown else {
			return false
		}
		let tag = sex == .male ? "HUSB" : "WIFE"
		var curnode = family.kid
		while let node = curnode {
			if node.tag == tag && node.val == person.key { return true }
			curnode = node.sib
		}
		return false
	}

	func famcLinks(recordIndex: RecordIndex) -> [(family: GedcomNode?, key: String, node: GedcomNode)] {
		// Generate FAMC links
		return [] // Implement based on GNode structure
	}

	func famsLinks(recordIndex: RecordIndex) -> [(family: GedcomNode?, key: String, node: GedcomNode)] {
		// Generate FAMS links
		return [] // Implement based on GNode structure
	}

	func children(recordIndex: RecordIndex) -> [GedcomNode] {
		// Return children of a family node
		return [] // Implement based on GNode structure
	}

    public func husband(recordIndex: RecordIndex) -> GedcomNode? {
        // Find the child node tagged "HUSB"
        guard let key = self.kid(withTag: "HUSB")?.val else {
            return nil
        }
        return recordIndex[key]
    }

    public func wife(recordIndex: RecordIndex) -> GedcomNode? {
        // Find the child node tagged "HUSB"
        guard let key = self.kid(withTag: "WIFE")?.val else {
            return nil
        }
        return recordIndex[key]
    }

	// getSex return the sex of a person (self)
	func getSex() -> SexType {
		let node = self.kid
		while let curnode = node {
			if curnode.tag == "SEX" {
				let value = curnode.tag
				if value == "M" { return .male }
				if value == "F" { return .female }
				if value == "U" { return .unknown }
				return .unknown
			}
		}
		return .unknown
	}

	func hasValidName() -> Bool {
		// Check if the node has a valid NAME field
		return true // Implement validation logic
	}

	func hasValidSex() -> Bool {
		// Check if the node has a valid SEX field
		return true // Implement validation logic
	}
}

