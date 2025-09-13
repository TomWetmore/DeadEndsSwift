//
//  DescendancyList.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 23 August 2025.
//  Last changed on 13 September 2025.
//
//  Experimental. Shows a descendancy list.

import SwiftUI
import DeadEndsLib

/// A person or spouse/family line in a descendancy.
struct DescendancyLine: Identifiable, Hashable {

    enum Kind { // Kind of line.
        case person(GedcomNode, Events) // Person, events.
        case spouse(GedcomNode, GedcomNode?, Events)  // Family, spouse?, events.
    }
    let kind: Kind  // Kind of line.
    let id: String  // Person or Family key.
    let depth: Int  // Indentation depth.

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

/// Holds date and place.
private struct Event {
    let date: String?
    let place: String?
}

/// Events shown on descendency lines.
struct Events {
    let birth: String?
    let death: String?
    let marriage: String?
}

/// Model for a descendancy list.
final class DescendancyListModel: ObservableObject {

    @Published var root: GedcomNode // Root Person of the descendancy.
    @Published var expandedPersons: Set<String> = [] // Expanded person keys.
    @Published var expandedUnions: Set<String> = []  // Expanded family keys.

    var maxGenerations: Int = 14

    /// Initializes a model with a root Person and empty expanded sets.
    init(root: GedcomNode) {
        self.root = root
    }

    /// Reroots this model to a new Person with empty expanded sets.
    func reRoot(_ person: GedcomNode) {
        root = person
        expandedPersons.removeAll()
        expandedUnions.removeAll()
    }

    /// Builds the Array of DescendancyLines. These are the lines that can appear in
    /// descendancy Views.
    func visibleLines(index: RecordIndex) -> [DescendancyLine] {

        var lines: [DescendancyLine] = []  // Returned DescendancyLines.
        // Vusited persons and families to prevent cycles.
        var visitedPersons = Set<String>()
        var visitedFamilies = Set<String>()

        /// Adds a Person to the DescendancyLines.
        func addPerson(_ person: GedcomNode, depth: Int, gen: Int) {
            guard let pkey = person.key else { return } // Can't fail.
            let events = Events(birth: person.child(withTag: "BIRT")?.child(withTag: "DATE")?.value,
                                death: person.child(withTag: "DEAT")?.child(withTag: "DATE")?.value,
                                marriage: nil)
            lines.append(DescendancyLine(kind: .person(person, events), id: pkey, depth: depth))
            // Stop if unexpanded, visited, or past max generation.
            guard expandedPersons.contains(pkey), !visitedPersons.contains(pkey), gen < maxGenerations
            else { return }
            visitedPersons.insert(pkey)

            // Add Spouse/Family lines for each FAMS the Person is a spouse in.
            let fkeys = person.children(withTag: "FAMS").compactMap { $0.value }
            for fkey in fkeys {
                guard let family = index[fkey] else { continue }
                addUnion(family, of: person, depth: depth + 1, gen: gen)
            }
        }

        /// Adds a Spouse (aka Union/Family) line to the DescendancyLines.
        func addUnion(_ family: GedcomNode, of person: GedcomNode, depth: Int, gen: Int) {
            guard let fKey = family.key, let pkey = person.key  else { return } // Can't fail.
            let hkey = family.value(forTag: "HUSB")
            let wkey = family.value(forTag: "WIFE")
            let skey: String? = {
                if hkey == pkey { return wkey }
                if wkey == pkey { return hkey }
                // Handle weird cases (there are weirder ones).
                if let h = hkey, h != pkey { return h }
                if let w = wkey, w != pkey { return w }
                return nil
            }()

            let spouse = skey.flatMap { index[$0] }
            let events = Events(birth: nil, death: nil,
                                marriage: family.child(withTag: "MARR")?.child(withTag: "DATE")?.value)
            lines.append(DescendancyLine(kind: .spouse(family, spouse, events), id: fKey, depth: depth))

            guard expandedUnions.contains(fKey), !visitedFamilies.contains(fKey) else { return }
            visitedFamilies.insert(fKey)

            // Add DescendencyLines for the children.
            let childKeys = family.children(withTag: "CHIL").compactMap { $0.value }
            for childKey in childKeys {
                guard let child = index[childKey] else { continue }
                addPerson(child, depth: depth + 1, gen: gen + 1)
            }
        }

        // Build Array of DescendancyLines recursively starting at the root Persont.
        addPerson(root, depth: 0, gen: 0)
        return lines
    }

    /// Toggles a DescendancyLine between expanded and unexpanded.
    func toggle(_ line: DescendancyLine) {
        switch line.kind {
        case .person(let person, _):  // Toggle a Person line.
            if let key = person.key {
                if expandedPersons.contains(key) { expandedPersons.remove(key) }
                else { expandedPersons.insert(key) }
            }
        case .spouse(let family, _, _):  // Toggle a Union line.
            if let key = family.key {
                if expandedUnions.contains(key) { expandedUnions.remove(key) }
                else { expandedUnions.insert(key) }
            }
        }
    }

    /// Determines whether a DesendancyLine is expanded.
    func isExpanded(_ line: DescendancyLine) -> Bool {
        switch line.kind {
        case .person(let p, _): return p.key.map { expandedPersons.contains($0) } ?? false
        case .spouse(let f, _, _):  return f.key.map { expandedUnions.contains($0) } ?? false
        }
    }
}

extension GedcomNode {

    /// Label for a Person.
    func personLabel(uppercaseSurname: Bool = false) -> String {
        return self.displayName()
    }
}

private struct DescPalette {
    let male: Color
    let female: Color
    let spouse: Color
    let unknown: Color
}

/// Palette for DecendancyView text.
private let palette = DescPalette(
    male: Color(red: 0, green: 0, blue: 0.6),
    female: Color(red: 0.6, green: 0, blue: 0),
    spouse: Color(red: 0.4, green: 0.4, blue: 0),
    unknown: .secondary,
)

/// SwiftUI View for a DescendancyList.
struct DescendancyListView: View {

    @EnvironmentObject var app: AppModel        // ← for navigation and global stuff
    let index: RecordIndex
    @StateObject private var model: DescendancyListModel
    private let indent: CGFloat = 18

    /// Creates a DescendancyListView; caller provides the root Person and the RecordIndex.
    init(root: GedcomNode, index: RecordIndex) {
        self.index = index
        // TODO: Understand the following statement:
        _model = StateObject(wrappedValue: DescendancyListModel(root: root))
        
    }

    /// The DescendencyListView body.
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            List {
                ForEach(model.visibleLines(index: index)) { line in
                    rowView(for: line)
                        .contentShape(Rectangle())
                }
            }
            .listStyle(.plain)
        }
    }

    private var header: some View {
        HStack {
            Text("Descendancy of \(model.root.personLabel())")
                .font(.headline)
            Spacer()
            Menu("Options") {
                Button("Collapse All", role: .none) {
                    model.expandedPersons.removeAll()
                    model.expandedUnions.removeAll()
                }
                Button("Expand Root Only") {
                    model.expandedPersons = [model.root.key].compactMap { $0 }.reduce(into: Set<String>()) { $0.insert($1) }
                    model.expandedUnions.removeAll()
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    /// Creates Views for DescendancyLines.
    @ViewBuilder
    private func rowView(for line: DescendancyLine) -> some View {

        HStack(spacing: 8) {
            // Make the indent and the gutter an expanded hit target.
            HStack(spacing: 0) {
                Color.clear.frame(width: CGFloat(line.depth) * indent, height: 12)

                // Chevron icon
                Image(systemName: model.isExpanded(line) ? "chevron.down" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .opacity(expandable(line) ? 1 : 0) // hide if not expandable
            }
            .contentShape(Rectangle()) // Use whole gutter for hit-testing.
            .onTapGesture { if expandable(line) { model.toggle(line) } }
            .accessibilityLabel(model.isExpanded(line) ? "Collapse" : "Expand")
            .accessibilityAddTraits(.isButton)
            .allowsHitTesting(expandable(line))  // Ignore taps when not expandable.

            // Lines and actions.
            switch line.kind {
            case .person(let person, let events):  // Handle Person line.
                personRow(person, events: events)
                    .contentShape(Rectangle())  // Make the row tappable.
                    .onTapGesture {
                        app.path.append(Route.descendancy(person))
                    }
                    .contextMenu {
                        Button("Make Root Here") {
                            model.reRoot(person)  // Reroot to current Person.
                        }
                        Button("Open in Person View") {
                            app.path.append(Route.person(person))  // Open current Person in PersonView.
                        }
                        Button("Show Families") {
                            if let key = person.key { model.expandedPersons.insert(key) }
                        }
                    }

            case .spouse(let family, let spouse, let events):  // Handle Spouse (Union/Family) line.
                spouseRow(spouse, events: events)
                    .contentShape(Rectangle())  // Make the row tappable.
                    .onTapGesture {
                        if let spouse = spouse {
                            app.path.append(Route.person(spouse))  // Open current spouse in PersonView.
                        }
                    }
                    .allowsHitTesting(spouse != nil)  // Disable taps when there is no spouse.
                    .opacity(spouse == nil ? 0.6 : 1)  // Visually indicate it's inactive REMOVE IF DOESN'T LOOK GOOD
                    .contextMenu {
                        Button("Expand Children") {
                            if let key = family.key { model.expandedUnions.insert(key) }
                        }
                        Button("Collapse") {
                            if let key = family.key { model.expandedUnions.remove(key) }
                        }
                        if let spouse = spouse {
                            Button("Open Spouse in Person View") {
                                app.path.append(Route.person(spouse))
                            }
                        }
                    }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private func personRow(_ person: GedcomNode, events: Events) -> some View {
        let color: Color = {
            switch (person.sexOf() ?? .unknown) {
            case .male:   return palette.male
            case .female: return palette.female
            case .unknown: return palette.unknown
            }
        }()

        return HStack(spacing: 6) {
            Text(person.sexSymbol)
                .baselineOffset(8)
                .padding(.trailing, -4)
            Text(person.personLabel())
                .padding(.leading, -4)
            if let birth = events.birth { Text("• \(birth)").foregroundStyle(.secondary) }
            if let death = events.death { Text("– \(death)").foregroundStyle(.secondary) }
        }
        .font(.system(.body, design: .rounded))
        .fontWeight(.medium)
        .foregroundStyle(color)
    }

    private func spouseRow(_ spouse: GedcomNode?, events: Events) -> some View {
        HStack(spacing: 6) {
            Text(spouse?.sexSymbol ?? "?")
                .baselineOffset(8)
                .padding(.trailing, -4)
            Text(spouse?.personLabel() ?? "(unknown spouse)")
            if let marriage = events.marriage { Text("married \(marriage)") }
        }
        .font(.system(.body, design: .rounded))
        .fontWeight(.medium)
        .foregroundStyle(palette.spouse)
    }

    /// Checks whether this descendancy line is expandable (has potential children).
    private func expandable(_ line: DescendancyLine) -> Bool {
        switch line.kind {
        case .person(let p, _):  // Expandable if the Person has and FAMS links.
            return !p.children(withTag: "FAMS").isEmpty
        case .spouse(let f, _, _):  // Expandable if the Family has any CHIL links.
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
