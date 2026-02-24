//
//  GedcomTag.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 4 February 2026.
//  Last changed on 24 February 2026.
//

import Foundation

/// Gedcom tags referred to in code.
public enum GedcomTag: String {
    case indi = "INDI"
    case fam  = "FAM"
    case sour = "SOUR"
    case name = "NAME"
    case sex  = "SEX"
    case plac = "PLAC"
    case birt = "BIRT"
    case deat = "DEAT"
    case date = "DATE"
    case famc = "FAMC"
    case fams = "FAMS"
    case head = "HEAD"
    case note = "NOTE"
    case husb = "HUSB"
    case wife = "WIFE"
    case chil = "CHIL"
    case marr = "MARR"
    case div  = "DIV"
    case buri = "BURI"
    case chr  = "CHR"
    case refn = "REFN"
}

extension GedcomNode {
    
    /// Check if node has specific tag.
    func hasTag(_ tag: GedcomTag) -> Bool { self.tag == tag.rawValue }
}

/// See if this works out.
public extension GedcomTag {
    static let INDI = GedcomTag.indi.rawValue
    static let FAM  = GedcomTag.fam.rawValue
    static let NAME = GedcomTag.name.rawValue
    static let SEX  = GedcomTag.sex.rawValue
    static let BIRT = GedcomTag.birt.rawValue
    static let DEAT = GedcomTag.deat.rawValue
    static let FAMS = GedcomTag.fams.rawValue
    static let FAMC = GedcomTag.famc.rawValue
    static let HUSB = GedcomTag.husb.rawValue
    static let WIFE = GedcomTag.wife.rawValue
    static let CHIL = GedcomTag.chil.rawValue
    static let DATE = GedcomTag.date.rawValue
    static let PLAC = GedcomTag.plac.rawValue
    static let MARR = GedcomTag.marr.rawValue
}
