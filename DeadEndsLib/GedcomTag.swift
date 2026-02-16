//
//  GedcomTag.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 4 February 2026.
//  Last changed on 12 February 2026.
//

import Foundation

/// Gedcom tags referred to in code.
enum GedcomTag: String {
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
