//
//  DescendanyListModel.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 3 February 2026.
//  Last changed on 3 February 2026.
//

import Foundation
import DeadEndsLib



/// Descendancy list model.
@Observable
final class DescendancyListModel {

    var root: Person
    let index: RecordIndex
    private var expandedPersons: Set<RecordKey> = []
    private var expandedFamilies: Set<RecordKey> = []
    var maxGenerations: Int = 14

    private(set) var lines: [DescendancyLine] = []

    /// Cache descendency line array.
    func rebuild() {
        lines = visibleLines()
    }

    /// Create model.
    init(root: Person, index: RecordIndex) {
        self.root = root
        self.index = index
        rebuild()
    }

    /// Reroot model.
    func reRoot(_ person: Person) {
        root = person
        expandedPersons.removeAll()
        expandedFamilies.removeAll()
        rebuild()
    }

    /// Build visible descendancy line array.
    func visibleLines() -> [DescendancyLine] {

        var lines: [DescendancyLine] = []
        var visitedPersons = Set<RecordKey>()
        var visitedFamilies = Set<RecordKey>()

        /// Add person to descendancy lines; recurse to expanded persons and families.
        func addPerson(_ person: Person, anchorKey: RecordKey?, depth: Int, gen: Int) {
            let personKey: RecordKey = person.key
            let events = Events(birth: person.birthEvent?.dateVal,
                                death: person.deathEvent?.dateVal,
                                marriage: nil)
             lines.append(
                 DescendancyLine(
                     kind: .person(person, events),
                     recordKey: personKey,
                     anchorKey: anchorKey,
                     depth: depth
                 )
             )
            // Stop if unexpanded, visited, or past max generation.
            guard expandedPersons.contains(personKey), !visitedPersons.contains(personKey), gen < maxGenerations
            else { return }
            visitedPersons.insert(personKey)

            // Add spouse line for each family person is a spouse in.
            for family in person.spouseFamilies(in: index) {
                addFamily(family, of: person, depth: depth + 1, gen: gen)
            }
        }

        /// Add family (spouse) line to descendancy lines.
        func addFamily(_ family: Family, of person: Person, depth: Int, gen: Int) {
            let familyKey = family.key
            let personKey = person.key
            let husbandKey = family.husband(in: index)?.key
            let wifeKey = family.wife(in: index)?.key
            let spouseKey: String? = {
                if husbandKey == personKey { return wifeKey }
                if wifeKey == personKey { return husbandKey }
                if let h = husbandKey, h != personKey { return h }  // Weird cases.
                if let w = wifeKey, w != personKey { return w }
                return nil
            }()

            let spouse = spouseKey.flatMap { index.person(for: $0) }
            let events = Events(birth: nil, death: nil,
                                marriage: family.marriageEvent?.dateVal)
            lines.append(
                DescendancyLine(
                    kind: .spouse(family, spouse, events),
                    recordKey: family.key,
                    anchorKey: personKey,
                    depth: depth)
            )

            guard expandedFamilies.contains(familyKey), !visitedFamilies.contains(familyKey) else { return }
            visitedFamilies.insert(familyKey)

            // Add descendancy lines for children.
            for child in family.children(in: index) {
                addPerson(child, anchorKey: familyKey, depth: depth + 1, gen: gen + 1)
            }
        }

        // Build descendancy lines recursively.
        addPerson(root, anchorKey: nil, depth: 0, gen: 0)
        return lines
    }

    /// Collapse (unexpand) all descendancy lines.
    func collapseAll() {
        expandedPersons.removeAll()
        expandedFamilies.removeAll()
        rebuild()
    }

    func expandRootOnly() {
        expandedPersons = [root.key]
        expandedFamilies.removeAll()
        rebuild()
    }

    func expandPerson(_ personKey: RecordKey) {
        expandedPersons.insert(personKey)
        rebuild()
    }

    func expandFamily(_ familyKey: RecordKey) {
        expandedFamilies.insert(familyKey)
        rebuild()
    }

    func collapseFamily(_ familyKey: RecordKey) {
        expandedFamilies.remove(familyKey)
        rebuild()
    }

    /// Toggle a descendancy line between expanded and unexpanded.
    func toggle(_ line: DescendancyLine) {
        switch line.kind {
        case .person(let person, _):  // Toggle person line.
            let key = person.key
            if expandedPersons.contains(key) { expandedPersons.remove(key) }
            else { expandedPersons.insert(key) }
        case .spouse(let family, _, _):  // Toggle spouse line.
            let key = family.key
            if expandedFamilies.contains(key) { expandedFamilies.remove(key) }
            else { expandedFamilies.insert(key) }
        }
        rebuild()
    }

    /// See if a desendancy line is expanded.
    func isExpanded(_ line: DescendancyLine) -> Bool {
        switch line.kind {
        case .person(let person, _):
            return expandedPersons.contains(person.key)
        case .spouse(let family, _, _):
            return expandedFamilies.contains(family.key)
        }
    }

    /// Collapse sub tree below a descendancy line.
    func collapseSubtree(at line: DescendancyLine) {
        guard let i = lines.firstIndex(where: { $0.id == line.id }) else { return }
        let base = lines[i].depth

        // Remove descendants (contiguous region)
        var j = i + 1
        while j < lines.count, lines[j].depth > base {
            switch lines[j].kind {
            case .person(let p, _):
                expandedPersons.remove(p.key)
            case .spouse(let f, _, _):
                expandedFamilies.remove(f.key)
            }
            j += 1
        }

        // Remove the node itself
        switch line.kind {
        case .person(let p, _):
            expandedPersons.remove(p.key)
        case .spouse(let f, _, _):
            expandedFamilies.remove(f.key)
        }

        rebuild()
    }
}

/// Person or spouse descendancy line in a descendancy list.
struct DescendancyLine: Identifiable, Hashable {

    enum Kind {
        case person(Person, Events)  // Person, birth?, death?.
        case spouse(Family, Person?, Events)  // Family, spouse?, marriage?.
    }
    let kind: Kind
    let recordKey: RecordKey
    let anchorKey: RecordKey?
    let depth: Int

    var id: String {  // Unique row id
        let a = anchorKey ?? "root"
        switch kind {
        case .person: return "p|\(recordKey)|\(a)"
        case .spouse: return "f|\(recordKey)|\(a)"
        }
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

/// Events on descendancy lines.
struct Events {
    let birth: String?
    let death: String?
    let marriage: String?
}
