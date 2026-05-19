//
//  ProgramInterface.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 19 May 2026.
//  Last changed on 19 May 2026.
//

import Foundation

/// The DeadEnds programming language includes a number of built-in functions
/// that interact with users while programs are running. The details of specific
/// user interface technologies are not encoded directly in these built-ins.
/// Instead, the built-ins call functions defined by the ProgramInterface
/// protocol. This allows different user interface implementations to be written
/// without changing the core interpreter.
///
/// The first implementation of this protocol uses SwiftUI for the macOS and
/// iPadOS versions of DeadEnds.
protocol ProgramInterface {

    // Direct prompts
    func getPerson(prompt: String?) async -> Person?
    func getPersonSet(prompt: String?) async -> PersonSet<ProgramValue>?
    func getFamily(prompt: String?) async -> Family?
    func getInteger(prompt: String?) async -> Int?
    func getString(prompt: String?) async -> String?

    // Choose from existing relationship/data context
    func chooseChild(from value: ProgramValue) async -> Person?
    func chooseFamily(of person: Person) async -> Family?
    func choosePerson(from set: PersonSet<ProgramValue>) async -> Person?
    func chooseSpouse(of person: Person) async -> Person?
    func chooseSubset(from set: PersonSet<ProgramValue>) async -> PersonSet<ProgramValue>?

    // Generic menu
    func menuChoose(from list: List, prompt: String?) async -> Int?
}

/*
 VOID getindi(INDI_V [,STRING])
 VOID getindiset(SET_V [,STRING])
 VOID getfam(FAM_V)
 VOID getint(INT_V [,STRING])
 VOID getstr(STRING_V [,STRING])

 INDI choosechild(INDI|FAM)
 FAM choosefam(INDI)
 INDI chooseindi(SET)
 INDI choosespouse(INDI)
 SET choosesubset(SET)

 INT menuchoose(LIST [,STRING])
 */
