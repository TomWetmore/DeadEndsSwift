//
//  UserInterface.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 19 May 2026.
//  Last changed on 22 May 2026.
//

import Foundation

/// The DeadEnds programming language includes some built-in functions that
/// interact with users while programs are running. The details of user
/// interface technologies are not included in those built-ins. Instead, the
/// built-ins call functions that conform to the UserInterface protocol
/// defined here. Different interface implementations can be written without
/// changing the core interpreter.

@MainActor
public protocol UserInterface {

    func getPerson(prompt: String?) async -> Person?
//    func getPersonSet(prompt: String?) async -> PersonSet<ProgramValue>?
//    func getFamily(prompt: String?) async -> Family?
    func getInteger(prompt: String?) async -> Int?
    func getString(prompt: String?) async -> String?

//    func chooseChild(from value: ProgramValue) async -> Person?
//    func chooseFamily(of person: Person) async -> Family?
//    func choosePerson(from set: PersonSet<ProgramValue>) async -> Person?
//    func chooseSpouse(of person: Person) async -> Person?
//    func chooseSubset(from set: PersonSet<ProgramValue>) async -> PersonSet<ProgramValue>?

    // Generic menu
//func menuChoose(from list: List, prompt: String?) async -> Int?
}

/*
 VOID getindiset(SET_V [,STRING])
 VOID getfam(FAM_V)
 INDI choosechild(INDI|FAM)
 FAM choosefam(INDI)
 INDI chooseindi(SET)
 INDI choosespouse(INDI)
 SET choosesubset(SET)
 INT menuchoose(LIST [,STRING])
 */
