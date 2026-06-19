//
//  PedigreeDetail.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 5 July 2025.
//  Last changed on 19 June 2026.
//

import SwiftUI
import DeadEndsLib

/// Pedigree layout information about a person in unit square coords.
private struct PedigreeNode: Identifiable {
    
    let id: UUID = UUID()
    let person: Person  // Person.
    let x: CGFloat  // X-coord in unit square.
    let y: CGFloat  // Y-coord in unit square.
}

/// Pedigree view that shows a person with its pedigree.
struct PedigreeDetail: View {

    @State private var layout: [PedigreeNode] = []
    @Environment(AppModel.self) var model

    let person: Person  // Root of Pedigree.
    let generations: Int  // Number of generations.
    let buttonWidth: CGFloat  // Max button width.

    /// Render the pedigree detail view.
    var body: some View {

        GeometryReader { geometry in

            ZStack {

                ForEach(0...generations, id: \.self) { gen in  // Generation columns.
                    let x = CGFloat(gen) / CGFloat(generations) * geometry.size.width
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                    }.stroke(Color.blue.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5]))
                }
                let colwidth = geometry.size.width / CGFloat(generations)  // Layout constants.
                let offset = colwidth / 2.0

                ForEach(layout) { node in  // Layout each person.
                    let x = node.x * geometry.size.width + offset  // View coords.
                    let y = node.y * geometry.size.height
                    PersonTile(person: node.person) { person in
                        model.path.append(Route.person(person))
                    }
                    .frame(width: min(colwidth, buttonWidth), alignment: .leading)
                    .position(x: x, y: y)
                }
            }
        }
        .task(id: "\(person.key)|\(generations)|\(model.database != nil)") {
            guard let database = model.database else {
                layout = []
                return
            }
            layout = buildPedigreeLayout(from: person,
                                         generations: generations,
                                         recordIndex: database.recordIndex)
        }
    }
}

/// Position the persons in a unit square; return the array of pedigree nodes.
private func buildPedigreeLayout(from person: Person,  generations: Int,
                                 recordIndex: RecordIndex) -> [PedigreeNode] {
    var pedigreeNodes = [PedigreeNode]()

    /// Internal function that builds the array of nodes.
    func addPerson(_ person: Person, gen: Int, index: Int) {
        let x = CGFloat(gen) / CGFloat(generations) // Unit square coords.
        let y = CGFloat(2 * index + 1) / CGFloat(1 << (gen + 1))
        pedigreeNodes.append(PedigreeNode(person: person, x: x, y: y))

        if gen < generations - 1 { // Recurse to next generation.
            if let father = person.father(in: recordIndex) {
                addPerson(father, gen: gen + 1, index: 2 * index)
            }
            if let mother = person.mother(in: recordIndex) {
                addPerson(mother, gen: gen + 1, index: 2 * index + 1)
            }
        }
    }

    addPerson(person, gen: 0, index: 0)  // Call function to build the nodes.
    return pedigreeNodes
}

/// Debug function that shows the pedigree nodes.
private func showPedigreeNodes(_ nodes: [PedigreeNode]) {
    for node in nodes { print("\(node.person.displayName()) at \(node.x), \(node.y)") }
}
