//
//  PersonEditorViewModelNew.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 1 October 2025.
//  Last changed on 1 October 2025.
//

import SwiftUI
import DeadEndsLib

@MainActor
final class PersonEditorViewModelNew: ObservableObject {
    // Published form fields (mirror existing model)
    @Published var name: String = ""
    @Published var sex: SexType? = nil
    @Published var birthDate: String = ""
    @Published var birthPlace: String = ""
    @Published var showDeath: Bool = false
    @Published var deathDate: String = ""
    @Published var deathPlace: String = ""

    // Expansion state for tree editor
    @Published var expanded: Set<UUID> = []

    // Backing person record + root node
    private(set) var person: Person
    @Published private(set) var root: GedcomNode

    init(person: Person) {
        self.person = person
        self.root = person.root
        // initialize fields if you like
    }

    // MARK: - Mutations
    func updateTag(for node: GedcomNode, newTag: String) {
        node.tag = newTag
        objectWillChange.send()
    }

    func updateValue(for node: GedcomNode, newValue: String) {
        node.val = newValue
        objectWillChange.send()
    }

    func updateChildValue(for parent: GedcomNode, tag: String, newValue: String) {
        if let child = parent.kid(withTag: tag) {
            child.val = newValue
        } else if !newValue.isEmpty {
            parent.addKid(tag: tag, val: newValue)
        }
        objectWillChange.send()
    }

    func addChild(to node: GedcomNode) {
        let newChild = GedcomNode(tag: "NEW")
        node.addKid(newChild)
        expanded.insert(node.id)
        objectWillChange.send()
    }

    func addSibling(to node: GedcomNode) {
        let newSibling = GedcomNode(tag: "NEW")
        node.addSib(newSibling)
        expanded.insert(node.id)
        objectWillChange.send()
    }

    func remove(_ node: GedcomNode) {
        node.removeKid()
        objectWillChange.send()
    }
}
