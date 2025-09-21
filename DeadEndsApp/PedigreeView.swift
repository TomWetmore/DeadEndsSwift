//
//  PedigreeView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 5 July 2025.
//  Last changed on 19 September 2025.
//

import SwiftUI
import DeadEndsLib

/// Structure with layout information about a Person.
struct PedigreeNode: Identifiable {
    let id: String  // Person's key; needed for Identifiable protocol.
    let person: Person  // Person.
    let x: CGFloat  // X-coordinate of Person in unit square.
    let y: CGFloat  // Y-coordinate of Person in unit square.
}

/// Shows a Person and their Pedigree. This is one of the full-window DeadEnds views.
struct PedigreeView: View {

    @State private var layout: [PedigreeNode] = []
    @EnvironmentObject var model: AppModel // Need the Database for the RecordIndex.
    let person: Person
    let generations: Int
    let buttonWidth: CGFloat

    /// Shows the PedigreeView.
    var body: some View {

        GeometryReader { geometry in
            ZStack {
                // Lines that divide the View into generation columns.
                ForEach(0...generations, id: \.self) { gen in
                    let x = CGFloat(gen) / CGFloat(generations) * geometry.size.width
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                    }.stroke(Color.blue.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5]))
                }
                // Layout constants.
                let colwidth = geometry.size.width / CGFloat(generations)
                let offset = colwidth / 2.0
                
                // Layout each Person, converting from unit square to View coordinates.
                ForEach(layout) { node in
                    let x = node.x * geometry.size.width + offset
                    let y = node.y * geometry.size.height
                    PersonRow(person: node.person) // TODO: Get a better View for the Person information.
                    //PersonButton(person: node.person)
                        .frame(width: min(colwidth, buttonWidth), alignment: .leading)
                        .position(x: x, y: y)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .navigationTitle("Pedigree")
        .onAppear {
            if layout.isEmpty, let database = model.database {
                layout = buildPedigreeLayout(from: person, generations: generations,
                    recordIndex: database.recordIndex
                )
            }
        }
    }
}

/// Positions Persons for a PedigreeView in a unit square; returns an Array of PedigreeNodes.
func buildPedigreeLayout(from person: Person,  generations: Int,
                         recordIndex: [String: GedcomNode]) -> [PedigreeNode] {
    var pedigreeNodes = [PedigreeNode]()

    /// Recursively builds the array of PedigreeNodes.
    func addPerson(_ person: Person, gen: Int, index: Int) {
        let x = CGFloat(gen) / CGFloat(generations) // Compute x-coordinate.
        let y = CGFloat(2 * index + 1) / CGFloat(1 << (gen + 1)) // Compute y-coordinate.
        let id = person.key // Unique identifier.
        pedigreeNodes.append(PedigreeNode(id: id, person: person, x: x, y: y))
        // Recurse to next generation.
        if gen < generations - 1 {
            if let father = person.father(in: recordIndex) {
                addPerson(father, gen: gen + 1, index: 2 * index)
            }
            if let mother = person.mother(in: recordIndex) {
                addPerson(mother, gen: gen + 1, index: 2 * index + 1)
            }
        }
    }

    // Start building the PedigreeNodes by adding the first person.
    addPerson(person, gen: 0, index: 0)
    //showPedigreeNodes(pedigreeNodes)  // DEBUG
    return pedigreeNodes
}

/// Debug function that shows an Array of PedigreeNodes on standard out.
private func showPedigreeNodes(_ nodes: [PedigreeNode]) {
    for node in nodes {
        print("\(node.person.displayName()) at \(node.x), \(node.y)")
    }
}
