//
//  FamilyGraphBuilder.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 15 August 2025.
//  Last changed on 15 August 2025.
//

import Foundation
import DeadEndsLib

/// Lightweight view-model node you’ll feed into tidy later.
public struct GraphNode: Hashable {
    public let id: String
    public let name: String
    public let subtitle: String?
    public let spouseNames: [String]
    public var children: [GraphNode] = []
}

/// Build a small, one-way family tree around `person` for FamilyView.
/// - up: generations to include upward (parents from the first FAMC)
/// - down: generations to include downward (children from the first FAMS)
/// - includeSpouses: include spouse names as annotations (no spouse traversal)
func buildFamilyGraph(
    //from person: GedcomNode,
    from person: Person,
    index: RecordIndex,
    up: Int,
    down: Int,
    includeSpouses: Bool
) -> GraphNode? {

    let pid = person.key

    var node = GraphNode(
        id: pid,
        name: person.displayName(),
        subtitle: lifespanLine(person),
        spouseNames: includeSpouses ? spouseNames(person, index: index) : []
    )

    var parents: [GraphNode] = []
    if up > 0,
       let famcKey = person.kid(withTag: "FAMC")?.val,   // first FAMC only
       let famc = index[famcKey] {

        // Up to 1 HUSB + 1 WIFE from that first FAMC
        let parentIDs = ["HUSB", "WIFE"]
            .compactMap { famc.kid(withTag: $0)?.val }

        for parentID in parentIDs {
            if let person = index.person(for: parentID),
               let pn = buildFamilyGraph(from: person, index: index, up: up - 1, down: 0, includeSpouses: false) {
                parents.append(pn)
            }
        }
    }

    var kids: [GraphNode] = []
    if down > 0,
       let famsKey = person.kid(withTag: "FAMS")?.val,   // first FAMS only
       let fams = index[famsKey] {

        // All CHIL in that first FAMS
        let childIDs = fams.kids(withTag: "CHIL").compactMap { $0.val }
        for cid in childIDs {
            if let c = index.person(for: cid),
               let cn = buildFamilyGraph(from: c, index: index, up: 0, down: down - 1, includeSpouses: includeSpouses) {
                kids.append(cn)
            }
        }
    }

    node.children = parents + kids
    return node
}

// MARK: - Small helpers (adjust to your lib if needed)

func lifespanLine(_ p: Person) -> String? {
    let b = "A BIRTH DATE" // p.birthDate?.simpleString ?? ""
    let d = "A DEATH CATE" // p.deathDate?.simpleString ?? ""
    if b.isEmpty && d.isEmpty { return nil }
    return "b. \(b)\(d.isEmpty ? "" : " – d. \(d)")"
}

func spouseNames(_ person: Person, index: RecordIndex) -> [String] {
    let families = person.kids(withTag: "FAMS").compactMap { $0.val }.compactMap { index.family(for: $0) }
    func spouseIn(_ fam: Family) -> Person? {
        let partnerKeys = (fam.kids(withTag: "HUSB") + fam.kids(withTag: "WIFE"))
            .compactMap { $0.val }
        let partners = partnerKeys.compactMap { index.person(for: $0) }
        return partners.first { $0 != person }
    }
    return families.compactMap { spouseIn($0)?.displayName() }
}
