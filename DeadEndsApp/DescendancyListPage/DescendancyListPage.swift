//
//  DescendancyListPage.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 23 August 2025.
//  Last changed on 3 February 2026.

import SwiftUI
import DeadEndsLib

private struct DescPalette {
    let male: Color
    let female: Color
    let spouse: Color
    let unknown: Color
}

/// Palette for page text.
private let palette = DescPalette(
    male: Color(red: 0, green: 0, blue: 0.6),
    female: Color(red: 0.6, green: 0, blue: 0),
    spouse: Color(red: 0.4, green: 0.4, blue: 0),
    unknown: .secondary,
)

/// Descendancy list page view.
struct DescendancyListPage: View {

    @EnvironmentObject var app: AppModel
    @State private var model: DescendancyListModel
    private let indent: CGFloat = 40

    /// Create a descendancy list view.
    init(root: Person, index: RecordIndex) {
        // TODO: Understand the following statement:
        _model = State(wrappedValue: DescendancyListModel(root: root, index: index))

    }

    /// Render a descendency list view.
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            List {
                //ForEach(model.visibleLines(index: index)) { line in
                ForEach(model.lines) { line in
                    rowView(for: line)
                        .contentShape(Rectangle())
                }
            }
            .listStyle(.plain)
        }
    }

    /// Render a descendancy list header.
    private var header: some View {
        HStack {
            Text("Descendancy of \(model.root.displayName())")
                .font(.headline)
            Spacer()
            Menu("Options") {
                Button("Collapse All", role: .none) {
                    model.collapseAll()
                }
                Button("Expand Root Only") {
                    model.expandRootOnly()
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    /// Render a descendancy line.
    @ViewBuilder
    private func rowView(for line: DescendancyLine) -> some View {

        HStack(spacing: 8) {
            // Make indent and gutter an expanded hit target.
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
                            model.expandPerson(person.key)
                        }
                        .disabled(person.kids(withTag: "FAMS").isEmpty)
                        Button("Collapse Subtree") {
                            model.collapseSubtree(at: line)
                        }
                        .disabled(!model.isExpanded(line)) // optional, but nice
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
                            model.expandFamily(family.key)
                        }
                        //.disabled(family.children(in: model.index).isEmpty)
                        .disabled(!expandable(line))
                        Button("Collapse") {
                            model.collapseFamily(family.key)
                        }
                        if let spouse = spouse {
                            Button("Open Spouse in Person View") {
                                app.path.append(Route.person(spouse))
                            }
                        }
                        Button("Collapse Subtree") {
                            model.collapseSubtree(at: line)
                        }
                        .disabled(!model.isExpanded(line))
                    }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    /// Render person row.
    private func personRow(_ person: Person, events: Events) -> some View {
        let color: Color = {
            switch person.sex {
            case .male:   return palette.male
            case .female: return palette.female
            case .unknown: return palette.unknown
            }
        }()

        return HStack(spacing: 6) {
            Text(person.sexSymbol)
                .baselineOffset(8)
                .padding(.trailing, -4)
            Text(person.displayName())
                .padding(.leading, -4)
            if let birth = events.birth { Text("• \(birth)").foregroundStyle(.secondary) }
            if let death = events.death { Text("– \(death)").foregroundStyle(.secondary) }
        }
        .font(.system(.body, design: .rounded))
        .fontWeight(.medium)
        .foregroundStyle(color)
    }

    /// Render spouse (family/union) row.
    private func spouseRow(_ spouse: Person?, events: Events) -> some View {
        HStack(spacing: 6) {
            Text(spouse?.sexSymbol ?? "?")
                .baselineOffset(8)
                .padding(.trailing, -4)
            Text(spouse?.displayName() ?? "(unknown spouse)")
            if let marriage = events.marriage { Text("married \(marriage)") }
        }
        .font(.system(.body, design: .rounded))
        .fontWeight(.medium)
        .foregroundStyle(palette.spouse)
    }

    /// Check if  descendancy line is expandable.
    private func expandable(_ line: DescendancyLine) -> Bool {
        switch line.kind {
        case .person(let p, _):  // Expandable if person has FAMS link.
            return !p.kids(withTag: "FAMS").isEmpty
        case .spouse(let f, _, _):  // Expandable if family has CHIL link.
            return !f.kids(withTag: "CHIL").isEmpty
        }
    }
}

