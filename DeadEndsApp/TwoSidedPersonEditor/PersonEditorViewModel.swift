//
//  PersonEditorViewModel.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 22 September 2025.
//  Last changed on 28 September 2025.
//

import Foundation
import DeadEndsLib

@MainActor
final class PersonEditorViewModel: ObservableObject {

    // MARK: - Published Fields
    @Published var name: String = ""
    @Published var sex: SexType? = nil
    @Published var birthDate: String = ""
    @Published var birthPlace: String = ""
    @Published var showDeath: Bool = false
    @Published var deathDate: String = ""
    @Published var deathPlace: String = ""
    @Published var expanded: Set<ObjectIdentifier> = []

    // Placeholder for future custom events
    struct CustomEvent: Identifiable {
        let id = UUID()
        var label: String
        var date: String
        var place: String
    }
    @Published var customEvents: [CustomEvent] = []

    // MARK: - Backing person record
    private(set) var person: Person

    // The live root node is rebuilt on demand
    @Published private(set) var root: GedcomNode

    // MARK: - Initialization
    init(person: Person) {
        self.person = person
        self.name = person.kidVal(forTag: "NAME") ?? ""
        self.sex = person.sex
        self.birthDate = person.kidVal(atPath: ["BIRT", "DATE"]) ?? ""
        self.birthPlace = person.kidVal(atPath: ["BIRT", "PLAC"]) ?? ""

        let deathDateVal = person.kidVal(atPath: ["DEAT", "DATE"]) ?? ""
        let deathPlaceVal = person.kidVal(atPath: ["DEAT", "PLAC"]) ?? ""
        self.deathDate = deathDateVal
        self.deathPlace = deathPlaceVal
        self.showDeath = !(deathDateVal.isEmpty && deathPlaceVal.isEmpty)

        // Build the initial tree
        self.root = GedcomNode(key: person.key, tag: "INDI")
        rebuildGedcomTree()
    }

    /// Rebuilds the Gedcom tree.
    func rebuildGedcomTree() {
        let previousExpanded = expanded
        let root = GedcomNode(key: person.key, tag: "INDI")

        if !name.isEmpty {
            root.addKid(tag: "NAME", val: name)
        }
        if let s = sex {
            root.addKid(tag: "SEX", val: s.rawValue)
        }
        if !birthDate.isEmpty || !birthPlace.isEmpty {
            let birt = root.addKid(tag: "BIRT", val: nil)
            if !birthDate.isEmpty { birt.addKid(tag: "DATE", val: birthDate) }
            if !birthPlace.isEmpty { birt.addKid(tag: "PLAC", val: birthPlace) }
            // Auto-expand BIRT when it’s created/has children

            // Schedule expansion after tree updates
            DispatchQueue.main.async {
                self.expanded.insert(ObjectIdentifier(birt))
            }
        }
        if showDeath && (!deathDate.isEmpty || !deathPlace.isEmpty) {
            let deat = root.addKid(tag: "DEAT")
            if !deathDate.isEmpty { deat.addKid(tag: "DATE", val: deathDate) }
            if !deathPlace.isEmpty { deat.addKid(tag: "PLAC", val: deathPlace) }
            // Auto-expand DEAT when it’s created/has children

            // Schedule expansion after tree updates
            DispatchQueue.main.async {
                self.expanded.insert(ObjectIdentifier(deat))
            }
        }

        // Defer publishing to avoid "Publishing changes from within view updates"
        DispatchQueue.main.async {
            self.root = root
            self.person = Person(root)!
            self.expanded = previousExpanded.union(ObjectIdentifierSet(pathTo: root))
        }
    }

    // MARK: - Reset Form
    func clear() {
        name = ""
        sex = nil
        birthDate = ""
        birthPlace = ""
        deathDate = ""
        deathPlace = ""
        showDeath = false
        customEvents = []
        rebuildGedcomTree()
    }

    // MARK: - Add Custom Event
    func addNewEvent() {
        customEvents.append(CustomEvent(label: "Event", date: "", place: ""))
        rebuildGedcomTree()
    }
}

// MARK: - Utility: ObjectIdentifier path to node

/// Returns the ancestor path from root to the specified node (inclusive).
private func pathTo(_ node: GedcomNode) -> [GedcomNode] {
    var path: [GedcomNode] = []
    var current: GedcomNode? = node
    while let n = current {
        path.insert(n, at: 0)
        current = n.dad
    }
    return path
}


/// Returns the array of ObjectIdentifiers for the given node's ancestor path.
private func ObjectIdentifierSet(pathTo node: GedcomNode) -> [ObjectIdentifier] {
    pathTo(node).map(ObjectIdentifier.init)
}


func randomKey() -> String {
    return "FAKE ID"
}
