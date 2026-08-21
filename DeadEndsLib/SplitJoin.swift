//
//  SplitJoin.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 23 December 2024.
//  Last changed on 21 August 2026.
//

import Foundation

// Splits a person GNode tree into its components.
//public func splitPerson(indi: Root) -> (name: Root?, sex: Root?, body: Root?, famc: Root?, fams: Root?) {
//	guard indi.tag == GedcomTag.INDI else {
//		fatalError("splitPerson called on non-person node")
//	}
//
//	var name: GedcomNode?
//	var sex: GedcomNode?
//	var body: GedcomNode?
//	var famc: GedcomNode?
//	var fams: GedcomNode?
//
//	var lnam: GedcomNode? = nil
//	var lfmc: GedcomNode? = nil
//	var lfms: GedcomNode? = nil
//	var last: GedcomNode? = nil
//
//	var node = indi.kid
//	indi.kid = nil
//
//	while let current = node {
//		let tag = current.tag
//		node = current.sib
//		current.sib = nil
//
//		switch tag {
//		case "NAME":
//			if name == nil { name = current } else { lnam?.sib = current }
//			lnam = current
//		case "SEX":
//			sex = current
//		case "FAMC":
//			if famc == nil { famc = current } else { lfmc?.sib = current }
//			lfmc = current
//		case "FAMS":
//			if fams == nil { fams = current } else { lfms?.sib = current }
//			lfms = current
//		default:
//			if body == nil { body = current } else { last?.sib = current }
//			last = current
//		}
//	}
//
//	return (name, sex, body, famc, fams)
//}
//
//// Joins a person GNode tree from its components.
//public func joinPerson(indi: GedcomNode, name: GedcomNode?, sex: GedcomNode?, body: GedcomNode?, famc: GedcomNode?, fams: GedcomNode?) {
//	guard indi.tag == GedcomTag.INDI else {
//		fatalError("joinPerson called on non-person node")
//	}
//
//	var last: GedcomNode? = nil
//	indi.kid = nil
//
//	func append(_ part: GedcomNode?) {
//		guard let part = part else { return }
//		if indi.kid == nil {
//			indi.kid = part
//		} else {
//			last?.sib = part
//		}
//		last = part
//		while last?.sib != nil {
//			last = last?.sib
//		}
//	}
//
//	append(name)
//	append(sex)
//	append(body)
//	append(famc)
//	append(fams)
//}
//
//// Splits a family GNode tree into its components.
//public func splitFamily(fam: Root) -> (husb: Root?, wife: Root?, chil: Root?, rest: Root?) {
//	guard fam.tag == "FAM" else {
//		fatalError("splitFamily called on non-family node")
//	}
//
//	var husb: GedcomNode?
//	var wife: GedcomNode?
//	var chil: GedcomNode?
//	var rest: GedcomNode?
//
//	var lhsb: GedcomNode? = nil
//	var lwfe: GedcomNode? = nil
//	var lchl: GedcomNode? = nil
//	var last: GedcomNode? = nil
//
//	var node = fam.kid
//	fam.kid = nil
//
//	while let current = node {
//		let tag = current.tag
//		node = current.sib
//		current.sib = nil
//
//		switch tag {
//		case "HUSB":
//			if husb == nil { husb = current } else { lhsb?.sib = current }
//			lhsb = current
//		case "WIFE":
//			if wife == nil { wife = current } else { lwfe?.sib = current }
//			lwfe = current
//		case "CHIL":
//			if chil == nil { chil = current } else { lchl?.sib = current }
//			lchl = current
//		default:
//			if rest == nil { rest = current } else { last?.sib = current }
//			last = current
//		}
//	}
//
//	return (husb, wife, chil, rest)
//}
//
//// Joins a family GNode tree from its components.
//public func joinFamily(fam: GedcomNode, husb: GedcomNode?, wife: GedcomNode?, chil: GedcomNode?, rest: GedcomNode?) {
//	guard fam.tag == "FAM" else {
//		fatalError("joinFamily called on non-family node")
//	}
//
//	var last: GedcomNode? = nil
//	fam.kid = nil
//
//	func append(_ part: GedcomNode?) {
//		guard let part = part else { return }
//		if fam.kid == nil {
//			fam.kid = part
//		} else {
//			last?.sib = part
//		}
//		last = part
//		while last?.sib != nil {
//			last = last?.sib
//		}
//	}
//
//	append(husb)
//	append(wife)
//	append(chil)
//	append(rest)
//}
//
//// normalizePerson puts a person GNode tree into a standard format.
//public func normalizePerson(_ indi: Root) {
//	let (names, sex, body, famcs, famss) = splitPerson(indi: indi)
//	joinPerson(indi: indi, name: names, sex: sex, body: body, famc: famcs, fams: famss)
//}
//
//// normalizeFamily puts a family GNode tree into a standard format.
//public func normalizeFamily(_ fam: Root) {
//	let (husb, wife, chil, body) = splitFamily(fam: fam)
//	joinFamily(fam: fam,husb: husb, wife: wife, chil: chil, rest: body)
//}
