//
//  SplitJoin.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 23 December 2024.
//  Last changed on 22 July 2025.
//

import Foundation

// Splits a person GNode tree into its components.
public func splitPerson(indi: GedcomNode) -> (name: GedcomNode?, refn: GedcomNode?, sex: GedcomNode?, body: GedcomNode?, famc: GedcomNode?, fams: GedcomNode?) {
	guard indi.tag == "INDI" else {
		fatalError("splitPerson called on non-person node")
	}

	var name: GedcomNode?
	var refn: GedcomNode?
	var sex: GedcomNode?
	var body: GedcomNode?
	var famc: GedcomNode?
	var fams: GedcomNode?

	var lnam: GedcomNode? = nil
	var lref: GedcomNode? = nil
	var lfmc: GedcomNode? = nil
	var lfms: GedcomNode? = nil
	var last: GedcomNode? = nil

	var node = indi.kid
	indi.kid = nil

	while let current = node {
		let tag = current.tag
		node = current.sib
		current.sib = nil

		switch tag {
		case "NAME":
			if name == nil { name = current } else { lnam?.sib = current }
			lnam = current
		case "REFN":
			if refn == nil { refn = current } else { lref?.sib = current }
			lref = current
		case "SEX":
			sex = current
		case "FAMC":
			if famc == nil { famc = current } else { lfmc?.sib = current }
			lfmc = current
		case "FAMS":
			if fams == nil { fams = current } else { lfms?.sib = current }
			lfms = current
		default:
			if body == nil { body = current } else { last?.sib = current }
			last = current
		}
	}

	return (name, refn, sex, body, famc, fams)
}

// Joins a person GNode tree from its components.
public func joinPerson(indi: GedcomNode, name: GedcomNode?, refn: GedcomNode?, sex: GedcomNode?, body: GedcomNode?, famc: GedcomNode?, fams: GedcomNode?) {
	guard indi.tag == "INDI" else {
		fatalError("joinPerson called on non-person node")
	}

	var last: GedcomNode? = nil
	indi.kid = nil

	func append(_ part: GedcomNode?) {
		guard let part = part else { return }
		if indi.kid == nil {
			indi.kid = part
		} else {
			last?.sib = part
		}
		last = part
		while last?.sib != nil {
			last = last?.sib
		}
	}

	append(name)
	append(refn)
	append(sex)
	append(body)
	append(famc)
	append(fams)
}

// Splits a family GNode tree into its components.
public func splitFamily(fam: GedcomNode) -> (refn: GedcomNode?, husb: GedcomNode?, wife: GedcomNode?, chil: GedcomNode?, rest: GedcomNode?) {
	guard fam.tag == "FAM" else {
		fatalError("splitFamily called on non-family node")
	}

	var refn: GedcomNode?
	var husb: GedcomNode?
	var wife: GedcomNode?
	var chil: GedcomNode?
	var rest: GedcomNode?

	var lref: GedcomNode? = nil
	var lhsb: GedcomNode? = nil
	var lwfe: GedcomNode? = nil
	var lchl: GedcomNode? = nil
	var last: GedcomNode? = nil

	var node = fam.kid
	fam.kid = nil

	while let current = node {
		let tag = current.tag
		node = current.sib
		current.sib = nil

		switch tag {
		case "REFN":
			if refn == nil { refn = current } else { lref?.sib = current }
			lref = current
		case "HUSB":
			if husb == nil { husb = current } else { lhsb?.sib = current }
			lhsb = current
		case "WIFE":
			if wife == nil { wife = current } else { lwfe?.sib = current }
			lwfe = current
		case "CHIL":
			if chil == nil { chil = current } else { lchl?.sib = current }
			lchl = current
		default:
			if rest == nil { rest = current } else { last?.sib = current }
			last = current
		}
	}

	return (refn, husb, wife, chil, rest)
}

// Joins a family GNode tree from its components.
public func joinFamily(fam: GedcomNode, refn: GedcomNode?, husb: GedcomNode?, wife: GedcomNode?, chil: GedcomNode?, rest: GedcomNode?) {
	guard fam.tag == "FAM" else {
		fatalError("joinFamily called on non-family node")
	}

	var last: GedcomNode? = nil
	fam.kid = nil

	func append(_ part: GedcomNode?) {
		guard let part = part else { return }
		if fam.kid == nil {
			fam.kid = part
		} else {
			last?.sib = part
		}
		last = part
		while last?.sib != nil {
			last = last?.sib
		}
	}

	append(refn)
	append(husb)
	append(wife)
	append(chil)
	append(rest)
}

// normalizePerson puts a person GNode tree into a standard format.
public func normalizePerson(_ indi: GedcomNode) {
	let (names, refns, sex, body, famcs, famss) = splitPerson(indi: indi)
	joinPerson(indi: indi, name: names, refn: refns, sex: sex, body: body, famc: famcs, fams: famss)
}

// normalizeFamily puts a family GNode tree into a standard format.
public func normalizeFamily(_ fam: GedcomNode) {
	let (refns, husb, wife, chil, body) = splitFamily(fam: fam)
	joinFamily(fam: fam, refn: refns, husb: husb, wife: wife, chil: chil, rest: body)
}
