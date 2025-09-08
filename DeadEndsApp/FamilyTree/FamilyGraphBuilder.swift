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
    from person: GedcomNode,
    index: RecordIndex,
    up: Int,
    down: Int,
    includeSpouses: Bool
) -> GraphNode? {

    guard let pid = person.key else { return nil }

    var node = GraphNode(
        id: pid,
        name: person.displayName(),
        subtitle: lifespanLine(person),
        spouseNames: includeSpouses ? spouseNames(person, ri: index) : []
    )

    var parents: [GraphNode] = []
    if up > 0,
       let famcKey = person.child(withTag: "FAMC")?.value,   // first FAMC only
       let famc = index[famcKey] {

        // Up to 1 HUSB + 1 WIFE from that first FAMC
        let parentIDs = ["HUSB", "WIFE"]
            .compactMap { famc.child(withTag: $0)?.value }

        for parentID in parentIDs {
            if let p = index[parentID],
               let pn = buildFamilyGraph(from: p, index: index, up: up - 1, down: 0, includeSpouses: false) {
                parents.append(pn)
            }
        }
    }

    var kids: [GraphNode] = []
    if down > 0,
       let famsKey = person.child(withTag: "FAMS")?.value,   // first FAMS only
       let fams = index[famsKey] {

        // All CHIL in that first FAMS
        let childIDs = fams.children(withTag: "CHIL").compactMap { $0.value }
        for cid in childIDs {
            if let c = index[cid],
               let cn = buildFamilyGraph(from: c, index: index, up: 0, down: down - 1, includeSpouses: includeSpouses) {
                kids.append(cn)
            }
        }
    }

    node.children = parents + kids
    return node
}

// MARK: - Small helpers (adjust to your lib if needed)

func lifespanLine(_ p: GedcomNode) -> String? {
    let b = "A BIRTH DATE" // p.birthDate?.simpleString ?? ""
    let d = "A DEATH CATE" // p.deathDate?.simpleString ?? ""
    if b.isEmpty && d.isEmpty { return nil }
    return "b. \(b)\(d.isEmpty ? "" : " – d. \(d)")"
}

func spouseNames(_ p: GedcomNode, ri: RecordIndex) -> [String] {
    let fams = p.children(withTag: "FAMS").compactMap { $0.value }.compactMap { ri[$0] }
    func spouseIn(_ fam: GedcomNode) -> GedcomNode? {
        let partnerKeys = (fam.children(withTag: "HUSB") + fam.children(withTag: "WIFE"))
            .compactMap { $0.value }
        let partners = partnerKeys.compactMap { ri[$0] }
        return partners.first { $0 != p }
    }
    return fams.compactMap { spouseIn($0)?.displayName() }
}
