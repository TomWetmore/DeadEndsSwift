import SwiftUI
import DeadEndsLib

struct FamilyView: View {
    @EnvironmentObject var model: AppModel
    let family: GedcomNode

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Family View")
                .font(.title)
                .padding(.bottom)

            if let husband = resolveRole("HUSB") {
                PersonRow(person: husband, relation: "Husband")
            }

            if let wife = resolveRole("WIFE") {
                PersonRow(person: wife, relation: "Wife")
            }

            Divider()
            Text("Children:")
                .font(.headline)

            ForEach(children, id: \.self) { child in
                PersonRow(person: child, relation: "Child")
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Family")
    }

    private func resolveRole(_ tag: String) -> GedcomNode? {
        guard let key = family.child(withTag: tag)?.value else { return nil }
        return model.database?.recordIndex[key]
    }

    private var children: [GedcomNode] {
        guard let ri = model.database?.recordIndex else { return [] }
        return family.children(withTag: "CHIL").compactMap { node in
            node.value.flatMap { ri[$0] }
        }
    }
}

// Reuse your PersonRow or PersonButton view for showing persons here.
