//
//  DeaktopView.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 22 October 2025.
//  Last changed on 19 January 2026.
//

import SwiftUI
import DeadEndsLib

/// View that contains draggable cards and supports genealogical activities.
struct DesktopView: View {

    @State private var model: DesktopModel
    @State private var showingSearchSheet = false

    /// Create a desktop view with a person card.
    init(person: Person) {
        
        let desktopModel = DesktopModel()
        desktopModel.addCard(
            kind: .person(person),
            position: CGPoint(x: 200, y: 200),
            size: CardSizes.startSize
        )
        _model = State(wrappedValue: desktopModel)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {

                // Background
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 118/255, green: 214/255, blue: 255/255),
                                Color(red: 90/255, green: 190/255, blue: 240/255)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .border(Color.gray.opacity(0.3))
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { model.selectedIDs.removeAll() }

                // Cards
                ForEach(model.cards) { card in
                    DraggableCard(model: model, cardID: card.id) {
                        SelectableCard(model: model, cardID: card.id) {
                            ResizeableCard(model: model, cardID: card.id) {
                                CardView(model: model, cardID: card.id)
                            }
                        }
                    }
                }
            }
            .coordinateSpace(name: "desktop")
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .contextMenu {
            Button("Add Person to Desktop...") {
                showingSearchSheet = true
            }
        }
        .sheet(isPresented: $showingSearchSheet) {
            PersonSearchSheet(model: model)
                .frame(minWidth: 500, minHeight: 200)
        }
    }
}

/// Sheet that allows a user to search for a Person and add its PersonCard to the Desktop.
struct PersonSearchSheet: View {

    @Environment(\.dismiss) var dismiss
    var model: DesktopModel
    @EnvironmentObject var appModel: AppModel

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
                                      size: CardSizes.startSize)
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
