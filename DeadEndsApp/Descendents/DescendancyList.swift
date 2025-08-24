//
//  DescendancyList.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 23 August 2025.
//  Last changed on 23 August 2025.
//

import SwiftUI
import DeadEndsLib

/// One row in an indented descendancy list.
struct DescendancyLine: Identifiable, Hashable {

    enum Kind: Hashable { // Kind of DescendancyLine.
        case person(GedcomNode) // Person
        case union(GedcomNode)  // Family
    }
    
    let id: String  // Person of Family key.
    let depth: Int  // Indentation level.
    let kind: Kind  // Kind of line.
}

/// Model for a descendancy list.
final class DescendancyListModel: ObservableObject {
    @Published var root: GedcomNode
    @Published var expandedPersons: Set<String> = [] // Expanded person keys.
    @Published var expandedUnions: Set<String> = []  // Expanded family keys.

    var maxGenerations: Int = 14

    /// Initializes a model.
    init(root: GedcomNode) {
        self.root = root
    }

    /// Re-roots this model to a new Person.
    func reRoot(_ person: GedcomNode) {
        root = person
        expandedPersons.removeAll()
        expandedUnions.removeAll()
    }

    /// Builds a flat, indented list of visible lines from the root.
    func visibleLines(index: RecordIndex) -> [DescendancyLine] {

        var out: [DescendancyLine] = []  // Array of DescendancyLines found by this method.
        var visitedPersons = Set<String>()  // Persons who have been seen.
        var visitedFamilies = Set<String>()  // Unions (families) that have been seen.

        // Local functions.
        func personKey(_ p: GedcomNode) -> String? { p.key }  // Return the key of a Person GedcomNode.
        func familyKey(_ f: GedcomNode) -> String? { f.key }  // Return the key of a Family GedcomNode.

        // Pushes a Person onto the output array of DescendancyLines.
        func pushPerson(_ p: GedcomNode, depth: Int, gen: Int) {
            guard let pkey = personKey(p) else { return }
            out.append(DescendancyLine(id: pkey, depth: depth, kind: .person(p)))
            // Stop if collapsed, visited, or past generations
            guard expandedPersons.contains(pkey),
                  !visitedPersons.contains(pkey),
                  gen < maxGenerations else { return }
            visitedPersons.insert(pkey)

            // Person → unions (FAMS)
            let fkeys = p.children(withTag: "FAMS").compactMap { $0.value }
            for (i, fkey) in fkeys.enumerated() {
                guard let fam = index[fkey] else { continue }
                pushUnion(fam, depth: depth + 1, gen: gen, order: i + 1)
            }
        }

        // Pushes a Union/Family onto the output array of DescendancyLines.
        func pushUnion(_ f: GedcomNode, depth: Int, gen: Int, order: Int) {
            guard let fKey = familyKey(f) else { return }
            out.append(DescendancyLine(id: fKey, depth: depth, kind: .union(f)))
            guard expandedUnions.contains(fKey),
                  !visitedFamilies.contains(fKey) else { return }
            visitedFamilies.insert(fKey)

            // Union → children (CHIL)
            let childKeys = f.children(withTag: "CHIL").compactMap { $0.value }
            for cKey in childKeys {
                guard let child = index[cKey] else { continue }
                pushPerson(child, depth: depth + 1, gen: gen + 1)
            }
        }

        // Start from root person (never auto-expanded unless in set)
        pushPerson(root, depth: 0, gen: 0)
        return out
    }

    // Toggles a DescendancyLine between expanded and unexpanded.
    func toggle(_ line: DescendancyLine) {
        switch line.kind {
        case .person(let p):  // Toggles a Person line.
            if let k = p.key {
                if expandedPersons.contains(k) { expandedPersons.remove(k) }
                else { expandedPersons.insert(k) }
            }
        case .union(let f):  // Toggles a Union line.
            if let k = f.key {
                if expandedUnions.contains(k) { expandedUnions.remove(k) }
                else { expandedUnions.insert(k) }
            }
        }
    }

    // Determines whether a DesendancyLine is expanded.
    func isExpanded(_ line: DescendancyLine) -> Bool {
        switch line.kind {
        case .person(let p): return p.key.map { expandedPersons.contains($0) } ?? false
        case .union(let f):  return f.key.map { expandedUnions.contains($0) } ?? false
        }
    }
}

//----------------------------------------------------------------------------------------

extension GedcomNode {

    /// Compact label for a Person.
    func personLabel(uppercaseSurname: Bool = false) -> String {
        if let name = self.child(withTag: "NAME")?.value {
            let parts = name.components(separatedBy: "/")
            if parts.count >= 2 {
                let given = parts[0].trimmingCharacters(in: .whitespaces)
                let surname = uppercaseSurname ? parts[1].uppercased() : parts[1]
                return given.isEmpty ? surname : "\(given) \(surname)"
            }
            return name
        }
        return "(no name)"
    }

    /// Compact label for a Union.
    func unionLabel(index: RecordIndex, uppercaseSurname: Bool = false) -> String {
        let husb = self.value(forTag: "HUSB").flatMap { index[$0]?.personLabel(uppercaseSurname: uppercaseSurname) }
        let wife = self.value(forTag: "WIFE").flatMap { index[$0]?.personLabel(uppercaseSurname: uppercaseSurname) }
        var base: String
        switch (husb, wife) {
        case let (h?, w?): base = "\(h) + \(w)"
        case let (h?, nil): base = "\(h) + ?"
        case let (nil, w?): base = "? + \(w)"
        default: base = "Union"
        }
        let marr = self.child(withTag: "MARR")?.child(withTag: "DATE")?.value
        if let marr, !marr.isEmpty { return "Union: \(base) (\(marr))" }
        return "Union: \(base)"
    }
}


struct DescendancyListView: View {
    @EnvironmentObject var model: AppModel     // your app model if useful elsewhere
    let index: RecordIndex

    @StateObject private var vm: DescendancyListModel

    private let indent: CGFloat = 18

    init(root: GedcomNode, index: RecordIndex) {
        self.index = index
        _vm = StateObject(wrappedValue: DescendancyListModel(root: root))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            List {
                ForEach(vm.visibleLines(index: index)) { line in
                    row(for: line)
                        .contentShape(Rectangle())
                }
            }
            .listStyle(.plain)
        }
    }

    private var header: some View {
        HStack {
            Text("Descendancy (root: \(vm.root.personLabel()))")
                .font(.headline)
            Spacer()
            Menu("Options") {
                Button("Collapse All", role: .none) {
                    vm.expandedPersons.removeAll()
                    vm.expandedUnions.removeAll()
                }
                Button("Expand Root Only") {
                    vm.expandedPersons = [vm.root.key].compactMap { $0 }.reduce(into: Set<String>()) { $0.insert($1) }
                    vm.expandedUnions.removeAll()
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func row(for line: DescendancyLine) -> some View {
        HStack(spacing: 8) {
            // Indentation
            Color.clear.frame(width: CGFloat(line.depth) * indent, height: 0)

            // Chevron
            Button {
                vm.toggle(line)
            } label: {
                Image(systemName: vm.isExpanded(line) ? "chevron.down" : "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 16, height: 16)
                    .opacity(disclosable(line) ? 1 : 0) // hide if no children
            }
            .buttonStyle(.plain)
            .disabled(!disclosable(line))

            // Label + actions
            switch line.kind {
            case .person(let p):
                personRow(p)
                    .contextMenu {
                        Button("Make Root") { vm.reRoot(p) }
                        Button("Open in PersonView") {
                            // Hook into your navigation to PersonView here
                            //model.openPerson(p) // if you have a helper
                        }
                        Button("Show Families") {
                            if let k = p.key { vm.expandedPersons.insert(k) }
                        }
                    }
                    .onTapGesture(count: 1) {
                        // Common single-tap behavior: make root (adjust if you prefer)
                        vm.reRoot(p)
                    }

            case .union(let f):
                Text(f.unionLabel(index: index))
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
                    .contextMenu {
                        Button("Expand Children") {
                            if let k = f.key { vm.expandedUnions.insert(k) }
                        }
                        Button("Collapse") {
                            if let k = f.key { vm.expandedUnions.remove(k) }
                        }
                    }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private func personRow(_ p: GedcomNode) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "person.crop.square")
            Text(p.personLabel())
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
            if let b = p.child(withTag: "BIRT")?.child(withTag: "DATE")?.value {
                Text("• \(b)").foregroundStyle(.secondary)
            }
            if let d = p.child(withTag: "DEAT")?.child(withTag: "DATE")?.value {
                Text("– \(d)").foregroundStyle(.secondary)
            }
        }
    }

    /// Whether this line can expand (i.e., has potential children)
    private func disclosable(_ line: DescendancyLine) -> Bool {
        switch line.kind {
        case .person(let p):
            // Disclosable if the person has any FAMS families
            return !p.children(withTag: "FAMS").isEmpty
        case .union(let f):
            // Disclosable if the family has any CHIL
            return !f.children(withTag: "CHIL").isEmpty
        }
    }
}

// Example: inside PersonView toolbar button
//Button("Descendancy List") {
//    showingDescList = true
//}
//.sheet(isPresented: $showingDescList) {
//    if let person = currentPerson {
//        DescListView(root: person, index: model.index)
//            .environmentObject(model) // if you use AppModel hooks
//            .frame(minWidth: 480, minHeight: 560)
//    }
//}
