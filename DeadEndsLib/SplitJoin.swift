//
//  SplitJoin.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 12/23/24.
//  Last changed on 12/24/24.
//

import Foundation

// Splits a person GNode tree into its components.
func splitPerson(indi: GedcomNode) -> (name: GedcomNode?, refn: GedcomNode?, sex: GedcomNode?, body: GedcomNode?, famc: GedcomNode?, fams: GedcomNode?) {
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

	var node = indi.firstChild
	indi.firstChild = nil

	while let current = node {
		let tag = current.tag
		node = current.nextSibling
		current.nextSibling = nil

		switch tag {
		case "NAME":
			if name == nil { name = current } else { lnam?.nextSibling = current }
			lnam = current
		case "REFN":
			if refn == nil { refn = current } else { lref?.nextSibling = current }
			lref = current
		case "SEX":
			sex = current
		case "FAMC":
			if famc == nil { famc = current } else { lfmc?.nextSibling = current }
			lfmc = current
		case "FAMS":
			if fams == nil { fams = current } else { lfms?.nextSibling = current }
			lfms = current
		default:
			if body == nil { body = current } else { last?.nextSibling = current }
			last = current
		}
	}

	return (name, refn, sex, body, famc, fams)
}

// Joins a person GNode tree from its components.
func joinPerson(indi: GedcomNode, name: GedcomNode?, refn: GedcomNode?, sex: GedcomNode?, body: GedcomNode?, famc: GedcomNode?, fams: GedcomNode?) {
	guard indi.tag == "INDI" else {
		fatalError("joinPerson called on non-person node")
	}

	var last: GedcomNode? = nil
	indi.firstChild = nil

	func append(_ part: GedcomNode?) {
		guard let part = part else { return }
		if indi.firstChild == nil {
			indi.firstChild = part
		} else {
			last?.nextSibling = part
		}
		last = part
		while last?.nextSibling != nil {
			last = last?.nextSibling
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
func splitFamily(fam: GedcomNode) -> (refn: GedcomNode?, husb: GedcomNode?, wife: GedcomNode?, chil: GedcomNode?, rest: GedcomNode?) {
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

	var node = fam.firstChild
	fam.firstChild = nil

	while let current = node {
		let tag = current.tag
		node = current.nextSibling
		current.nextSibling = nil

		switch tag {
		case "REFN":
			if refn == nil { refn = current } else { lref?.nextSibling = current }
			lref = current
		case "HUSB":
			if husb == nil { husb = current } else { lhsb?.nextSibling = current }
			lhsb = current
		case "WIFE":
			if wife == nil { wife = current } else { lwfe?.nextSibling = current }
			lwfe = current
		case "CHIL":
			if chil == nil { chil = current } else { lchl?.nextSibling = current }
			lchl = current
		default:
			if rest == nil { rest = current } else { last?.nextSibling = current }
			last = current
		}
	}

	return (refn, husb, wife, chil, rest)
}

// Joins a family GNode tree from its components.
func joinFamily(fam: GedcomNode, refn: GedcomNode?, husb: GedcomNode?, wife: GedcomNode?, chil: GedcomNode?, rest: GedcomNode?) {
	guard fam.tag == "FAM" else {
		fatalError("joinFamily called on non-family node")
	}

	var last: GedcomNode? = nil
	fam.firstChild = nil

	func append(_ part: GedcomNode?) {
		guard let part = part else { return }
		if fam.firstChild == nil {
			fam.firstChild = part
		} else {
			last?.nextSibling = part
		}
		last = part
		while last?.nextSibling != nil {
			last = last?.nextSibling
		}
	}

	append(refn)
	append(husb)
	append(wife)
	append(chil)
	append(rest)
}

// normalizePerson puts a person GNode tree into a standard format.
func normalizePerson(_ indi: GedcomNode) {
	let (names, refns, sex, body, famcs, famss) = splitPerson(indi: indi)
	joinPerson(indi: indi, name: names, refn: refns, sex: sex, body: body, famc: famcs, fams: famss)
}

// normalizeFamily puts a family GNode tree into a standard format.
func normalizeFamily(_ fam: GedcomNode) {
	let (refns, husb, wife, chil, body) = splitFamily(fam: fam)
	joinFamily(fam: fam, refn: refns, husb: husb, wife: wife, chil: chil, rest: body)
}
