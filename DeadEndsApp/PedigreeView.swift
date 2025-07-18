//
//  PedigreeView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 5 July 2025.
//  Last changed on 13 July 2025.
//

import SwiftUI
import DeadEndsLib

// PedigreeNode stores layout info about a person.
struct PedigreeNode: Identifiable {
    let id: String
    let person: GedcomNode
    let x: CGFloat
    let y: CGFloat
}

// PedigreeView shows a person with pedigree. It is one of the full-window DeadEnds views.
struct PedigreeView: View {

    @EnvironmentObject var model: AppModel
    let person: GedcomNode
    let generations: Int
    let buttonWidth: CGFloat

    @State private var layout: [PedigreeNode] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Show vertical lines to separate the view into generation columns.
                ForEach(0...generations, id: \.self) { gen in
                    let x = CGFloat(gen) / CGFloat(generations) * geometry.size.width
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                    }.stroke(Color.blue.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5]))
                }
                // Constants used in layout calculations.
                let colwidth = geometry.size.width / CGFloat(generations)
                let offset = colwidth / 2.0
                // Layout each Person in the vew.
                ForEach(layout) { node in
                    let x = node.x * geometry.size.width + offset
                    let y = node.y * geometry.size.height
                    PersonButton(person: node.person)
                        .frame(width: min(colwidth, buttonWidth), alignment: .leading)
                        .position(x: x, y: y)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .navigationTitle("Pedigree")
        .onAppear {
            if layout.isEmpty, let db = model.database {
                layout = buildPedigreeLayout(
                    from: person,
                    generations: generations,
                    recordIndex: db.recordIndex
                )
            }
        }
    }
}

// buildPedigreeLayout lays out persons in a pedigree in a unit square and returns information about
// them in an array of PedigreeNode structures.
func buildPedigreeLayout(from person: GedcomNode, // Root person of pedigree.
                         generations: Int, // Number of generations in pedigree.
                         recordIndex: [String: GedcomNode]) // Record index from database.
                            -> [PedigreeNode] { // Returns the array of PedigreeNodes
    var pedigreeNodes = [PedigreeNode]()

    // addPerson is a local function that recursively builds an array of PedigreeNodes.
    func addPerson(_ person: GedcomNode, gen: Int, index: Int) {
        let x = CGFloat(gen) / CGFloat(generations) // Compute x coordinate in unit square.
        let y = CGFloat(2 * index + 1) / CGFloat(1 << (gen + 1)) // Compute y coordinate in unit square.
        let id = person.key ?? UUID().uuidString // Give each PedigreeNode an identifier.
        pedigreeNodes.append(PedigreeNode(id: id, person: person, x: x, y: y))
        // Recurse to next generation.
        if gen < generations - 1 {
            if let father = person.father(index: recordIndex) {
                addPerson(father, gen: gen + 1, index: 2 * index)
            }
            if let mother = person.mother(index: recordIndex) {
                addPerson(mother, gen: gen + 1, index: 2 * index + 1)
            }
        }
    }

    // Start layout recursion by adding the first person to pedigreeNodes.
    addPerson(person, gen: 0, index: 0)
    // showPedigreeNodes(nodes: pedigreeNodes) // TODO: Remove this DEBUG statement.
    return pedigreeNodes
}

// showPedigreeNodes is a debug function that shows an array of PedigreeNodes.
private func showPedigreeNodes(nodes: [PedigreeNode]) {
    for node in nodes {
        print("\(node.person.displayName) at \(node.x), \(node.y)")
    }
}
