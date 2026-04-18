//
//  RootView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 24 June 2025.
//  Last changed on 17 April 2026.

/// RootView is the root view of the DeadEndsApp. If the database does
/// not exist the Load Gedcom view is shown. If there is a database but
/// the navigataion path is empty the person selection view is shown.
/// Otherwise the page for the current navigation is route is shown.

import SwiftUI
import DeadEndsLib

/// Navigation stack values.
enum Route: Hashable {
    case person(Person)
    case pedigree(Person)
    case family(Family)
    case descendants(Person)
    case familyTree(Person)
    case descendancy(Person)
    case personEditor(Person)
    case gedcomTreeEditor(Person)
    case gedcomFamilyEditor(Family)
    case desktop(Person)
    case desktopFamily(Family)  // Ugly name.
    case program
}

/// Put the record index into the SwiftUI environment.
private struct RecordIndexKey: EnvironmentKey {
    static let defaultValue: RecordIndex = RecordIndex()
}
extension EnvironmentValues {
    var recordIndex: RecordIndex {
        get { self[RecordIndexKey.self] }
        set { self[RecordIndexKey.self] = newValue }
    }
}

/// Root View of the DeadEnds App.
struct RootView: View {
    @EnvironmentObject var model: AppModel

    /// Render the root view.
    var body: some View {

        NavigationStack(path: $model.path) {
            VStack {
                if model.database == nil {
                    LoadGedcomFileView()
                        .navigationTitle(Text("Loading..."))
                } else if model.path.isEmpty {
                    PersonSelectionView()
                }
            }
            // Build page for route on the navigation stack; runs when model.path.append is called.
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .person(let person):
                    PersonPage(person: person)
                case .pedigree(let person):
                    PedigreePage(person: person, generations: 4, buttonWidth: 400)
                case .family(let family):
                    FamilyPage(family: family)
                case .descendants(let p):
                    DescendantsPage(root: p)
                case .familyTree(let person):
                    FamilyTreeView(person: person)
                case .personEditor(let person):
                    // Create PersonEditorView with closure that runs when save button is pushed.
                    PersonEditorView(person: person) { newPerson in
                        model.database?.updatePerson(newPerson)
                        model.path.removeLast()  // Pop the editor view.
                    }
                case .gedcomTreeEditor(let person):
                    if let database = model.database {
                        GedcomEditorPage(database: database, root: person.root)
                    } else {
                        Text("No database loaded")
                    }
                case .descendancy(let person):
                    if let idx = model.database?.recordIndex {
                        DescendancyListPage(root: person, index: idx)
                            .environmentObject(model)
                            .navigationTitle("Descendancy")
                    } else {
                        Text("No record index or person available.")
                    }
                case .desktop(let person):
                    DesktopView(person: person)
                case .desktopFamily(let fam):
                    DesktopView(family: fam)
                case .gedcomFamilyEditor(_):
                    Text("hello")
                case .program:
                    ProgramPage(
                        model: ProgramModel(
                            programName: "Test Program",
                            sourceText: ""
                        ),
                        compiler: DeadEndsProgramCompiler()
                    )
                }
            }
        }
        .environment(\.recordIndex, model.database?.recordIndex ?? RecordIndex())
    }
}
