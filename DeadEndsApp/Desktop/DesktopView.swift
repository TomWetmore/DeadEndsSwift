//
//  DeaktopView.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 22 October 2025.
//  Last changed on 16 November 2025.
//

import SwiftUI
import DeadEndsLib

/// View that contains DraggableCardViews and supports genealogical activities.
struct DesktopView: View {

    @State private var model: DesktopModel
    @State private var showingSearchSheet = false

    /// Create a DesktopView with a first PersonCard; also creates the DesktopModel.
    init(person: Person) {
        let desktopModel = DesktopModel() // Create model as an ordinary class object.
        desktopModel.addCard(kind: .person(person), position: CGPoint(x: 200, y: 200), // Add a Person card to it.
                             size: CardConstants.startSize)
        _model = State(wrappedValue: desktopModel) // Install the model into @StateObject memory.
    }

    /// DesktopView's body property.
    var body: some View {
        GeometryReader { geo in  // Defines available desktop area.

            // This View holds the whole Desktop.
            ZStack {
                Rectangle()  // Background is a blue gradient covering the desktop.
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 118/255, green: 214/255, blue: 255/255),
                                Color(red: 90/255, green: 190/255, blue: 240/255)
                            ]),
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .border(Color.gray.opacity(0.3))
                    .ignoresSafeArea()

                // FIRST TOOL EXPERIMENT
                MergePersonTool(model: model) // DEBUG: Turn this back on soon

                // Card layer. Card views measure their frames in “desktop” space, and are placed on
                // the Desktop surface.
                ForEach(model.cards) { card in
                    DraggableCard(model: model, cardID: card.id) {
                        ResizeableCard(model: model, cardID: card.id) {
                            CardView(model: model, cardID: card.id)
                        }
                    }
                }
            }
            // Define the coordinate space for all subviews. (.frame(in: .named("desktop")).
            .coordinateSpace(name: "desktop")
            .frame(minWidth: 800, minHeight: 500)
        }

        // Context menu for the Desktop.
        .contextMenu {
            Button("Add Person to Desktop...") {
                showingSearchSheet = true
            }
        }
        .sheet(isPresented: $showingSearchSheet) {
            PersonSearchSheet(model: model)
                .frame(minWidth: 500, minHeight: 400)
        }
    }
}

/// Sheet that allows a user to search for a Person and add its PersonCard to the Desktop.
struct PersonSearchSheet: View {

    @Environment(\.dismiss) var dismiss
    var model: DesktopModel
    @EnvironmentObject var appModel: AppModel  // Provides Database access.

    @State private var query: String = ""
    @State private var results: [PersonMatch] = []

    var body: some View {
        VStack(alignment: .leading) {
            Text("Search for a person:")
                .font(.headline)

            HStack {
                TextField("Enter name...", text: $query)
                    .onSubmit { doSearch() }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Search") { doSearch() }
            }

            if results.isEmpty {
                Text("No results.").italic()
            } else {
                List(results) { match in
                    Button(match.displayLine) {
                        model.addCard(kind: .person(match.person), position: CGPoint(x: 100, y: 100),
                                      size: CardConstants.startSize)
                        dismiss()
                    }
                }
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction) // ⎋ Escape key will also dismiss
            }
            .padding(.top)
        }
        .padding()
    }

    private func doSearch() {
        guard let database = appModel.database else { return }
        results = database.persons(withName: query)
            .map { PersonMatch(id: $0.key, person: $0) }
            .sorted {
                switch ($0.person.gedcomName, $1.person.gedcomName) {
                case let (l?, r?): return l < r
                case (nil, nil):   return $0.id < $1.id
                case (nil, _):     return false
                case (_, nil):     return true
                }
            }
    }
}
