//
//  Person.swift
//  DeadEndsLib
//
//  Created by Thomas Wetmore on 13 April 2025.
//  Last changed on 22 June 2025.
//

import Foundation

// GedcomNode extension where the GedcomNode is the root of a Person record.
extension GedcomNode {

    // isFemale returns true if a person is female.
    func isFemale() -> Bool {
        guard self.tag == "INDI" else {
            fatalError("Called isFemale on a non-person node.")
        }
        guard let sexNode = self.childrenByTag["SEX"]?.first else {
            return false
        }
        return sexNode.value?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "F"
    }

    // isMale returns true if a person is male.
    func isMale() -> Bool {
        guard self.tag == "INDI" else {
            fatalError("Called isMale on a non-person node.")
        }
        guard let sexNode = self.childrenByTag["SEX"]?.first else {
            return true
        }
        return sexNode.value?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "M"
    }

    // father returns the first father (first HUSB in first FAMC) of this person.
    func father(index: RecordIndex) -> GedcomNode? {
        guard let famKey = self.value(forTag: "FAMC"),
              let fam = index[famKey],
              let fatherKey = fam.value(forTag: "HUSB") else {
            return nil
        }
        return index[fatherKey]
    }

    func revisedFather(index: RecordIndex) -> GedcomNode? {
        for famcKey in self.values(forTag: "FAMC") {
            guard let fam = index[famcKey],
                  let husbKey = fam.value(forTag: "HUSB"),
                  let father = index[husbKey] else {
                continue
            }
            return father
        }
        return nil
    }

    // Find the father of this individual.
    func RRRfather(in index: RecordIndex) -> GedcomNode? {
        for famc in children(withTag: "FAMC") {
            guard let famKey = famc.value else { continue }
            guard let family = index[famKey] else { continue }
            if let husb = family.child(withTag: "HUSB"),
               let husbKey = husb.value,
               let father = index[husbKey] {
                return father
            }
        }
        return nil
    }

    func myFather(in index: RecordIndex) -> GedcomNode? {
        for famc in children(withTag: "FAMC") {
            guard let fkey = famc.value else { continue }
            guard let family = index[fkey] else { continue }
            guard let husb = family.child(withTag: "HUSB") else { continue }
            guard let hkey = husb.value else { continue }
            guard let father = index[hkey] else { continue }
            return father
        }
        return nil
    }

    // mother returns the first mother (first WIFE in first FAMC of this person.
    func mother(index: RecordIndex) -> GedcomNode? {
        guard let famKey = self.value(forTag: "FAMC"),
              let fam = index[famKey],
              let motherKey = fam.value(forTag: "WIFE") else { return nil
        }
        return index[motherKey]
    }
}

extension GedcomNode {

    // previousSibling returns the previous sibling of a person.
    func previousSibling(index: RecordIndex) -> GedcomNode? {
        // Get the family the person is a child in.
        guard let famKey = self.value(forTag: "FAMC"), let family = index[famKey] else {
            return nil
        }
        // Get the children of the family.
        let children = family.children(index: index)
        // Get the previous sibling unless self is the first.
        guard let indexOfSelf = children.firstIndex(of: self), indexOfSelf > 0 else {
            return nil
        }
        return children[indexOfSelf - 1]
    }

    // nextSibling returns the next sibling of person 'self'.
    func nextSibling(index: RecordIndex) -> GedcomNode? {
        // Get the family the person is a child in.
        guard let famKey = self.value(forTag: "FAMC"), let family = index[famKey] else {
            return nil
        }
        // Get the children of the family.
        let children = family.children(index: index)
        // Get the next sibling unless self is the last.
        guard let indexOfSelf = children.firstIndex(of: self), indexOfSelf < children.count - 1 else {
            return nil
        }
        return children[indexOfSelf + 1]
    }
}



