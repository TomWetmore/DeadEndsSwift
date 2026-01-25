//
//  DeaktopView.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 22 October 2025.
//  Last changed on 25 January 2026.
//

import SwiftUI
import DeadEndsLib

/// View that contains draggable cards and supports genealogical activities.
struct DesktopView: View {

    @EnvironmentObject var appModel: AppModel
    @State private var model: DesktopModel
    @State private var showingSearchSheet = false
    @State private var marqueeStart: CGPoint? = nil
    @State private var marqueeRect: CGRect? = nil
    private let seedFamily: Family?
    @State private var didSeed = false

    /// Create desktop with single person.
    init(person: Person) {
        let desktopModel = DesktopModel()
        desktopModel.addCard(
            kind: .person(person),
            position: CGPoint(x: 200, y: 200),
            size: CardSizes.startSize
        )
        self.seedFamily = nil
        _model = State(wrappedValue: desktopModel)
    }

    /// Create desktop with family group.
    init(family: Family) {
        self.seedFamily = family
        _model = State(wrappedValue: DesktopModel())
    }

    // Desktop view.
    var body: some View {

        GeometryReader { geo in
            ZStack {
                background  // Blue background.
                    .gesture(marqueeGesture)  // Marquee gesture.

                MarqueeOverlay(rect: marqueeRect)  // Marquee rectangle when active.

                cardsLayer // Cards on desktop.
            }
            .coordinateSpace(name: "desktop")
            .onAppear {
                seedIfNeeded(desktopSize: geo.size)
            }
            //.onPreferenceChange(CardFramePrefKey.self) { cardFrames = $0 }  // Now using model rects.
        }
        .contextMenu { desktopContextMenu }
        .sheet(isPresented: $showingSearchSheet) {
            PersonSearchSheet(model: model)
                .frame(minWidth: 500, minHeight: 200)
        }
    }

    /// Marquee drag gesture.
    private var marqueeGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                if marqueeStart == nil { marqueeStart = value.startLocation }
                let s = marqueeStart ?? value.startLocation
                let rect = CGRect(
                    x: min(s.x, value.location.x),
                    y: min(s.y, value.location.y),
                    width: abs(value.location.x - s.x),
                    height: abs(value.location.y - s.y)
                )
                marqueeRect = rect

                // Selection: intersects is usually the nicest feel
//                let hit = Set(cardFrames.compactMap { (id, frame) in
//                    frame.intersects(rect) ? id : nil
//                })
//                model.selectedIDs = hit

                // Selection: intersects is usually the nicest feel
                let hit = Set(model.cards.compactMap { card in
                    card.rect.intersects(rect) ? card.id : nil
                })

                if hit != model.selectedIDs {
                    model.selectedIDs = hit
                }


            }
            .onEnded { _ in
                marqueeStart = nil
                marqueeRect = nil
            }
    }

    /// Marquee overlay view.
    private struct MarqueeOverlay: View {
        let rect: CGRect?

        var body: some View {
            if let rect {
                ZStack {
                    Rectangle().fill(.primary.opacity(0.06))
                    Rectangle().stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                }
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
                .allowsHitTesting(false)
            }
        }
    }

    /// Blue background view of desktop.
    private var background: some View {
        Rectangle()
            .fill(Self.desktopGradient)
            .border(Color.gray.opacity(0.3))
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { model.selectedIDs.removeAll() }  // Tap deselects all cards.
    }

    /// Card layer view.
    private var cardsLayer: some View {
        ForEach(model.cards) { card in
            DraggableCard(model: model, cardID: card.id) {
                SelectableCard(model: model, cardID: card.id) {
                    ResizeableCard(model: model, cardID: card.id) {
                        CardView(model: model, cardID: card.id)
                            //.reportCardFrame(id: card.id)
                    }
                }
            }
        }
    }

    /// Desktop gradient.
    private static let desktopGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 118/255, green: 214/255, blue: 255/255),
            Color(red: 90/255, green: 190/255, blue: 240/255)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Add family to desktop if needed.
    private func seedIfNeeded(desktopSize: CGSize) {
        guard !didSeed else { return }
        didSeed = true

        guard let family = seedFamily else { return }
        guard let index = appModel.database?.recordIndex else { return }
        let parents = family.parents(in: index)
        let children = family.children(in: index)
        layoutFamily(parents: parents, children: children, desktopSize: desktopSize)  // Layout family.
    }

    /// Layout family on desktop.
    private func layoutFamily(parents: [Person], children: [Person], desktopSize: CGSize) {
        let parentY: CGFloat = desktopSize.height * 0.25  // Offsets to parent and child rows.
        let childY: CGFloat  = desktopSize.height * 0.55

        let parentSpacing: CGFloat = CardSizes.startSize.width * 1.2  // Inter card spacing.
        let childSpacing: CGFloat  = CardSizes.startSize.width * 1.05

        let px0 = desktopSize.width/2 - parentSpacing * CGFloat(max(parents.count - 1, 0))/2  // Parents.
        for (i, p) in parents.enumerated() {
            let x = px0 + CGFloat(i) * parentSpacing
            model.addCard(kind: .person(p), position: CGPoint(x: x, y: parentY), size: CardSizes.startSize)
        }

        let cx0 = desktopSize.width/2 - childSpacing * CGFloat(max(children.count - 1, 0))/2  // Children.
        for (i, c) in children.enumerated() {
            let x = cx0 + CGFloat(i) * childSpacing
            model.addCard(kind: .person(c), position: CGPoint(x: x, y: childY), size: CardSizes.startSize)
        }
    }
}

/// Sheet to search for a Person and add its card to the desktop.
struct PersonSearchSheet: View {

    @Environment(\.dismiss) var dismiss
    @Bindable var model: DesktopModel
    @EnvironmentObject var appModel: AppModel
    @State private var didSearch = false

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

            if didSearch && results.isEmpty {
                Text("No results.").italic()
            } else {
                List(results) { match in
                    Button(match.displayLine) {
                        // Experiment; put card at upper left corner of desktop.
                        let x = CardSizes.startSize.width / 2
                        let y = CardSizes.startSize.height / 2
                        model.addCard(kind: .person(match.person), position: CGPoint(x: x, y: y),
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
                .keyboardShortcut(.cancelAction) // Escape key also dismisses.
            }
            .padding(.top)
        }
        .padding()
    }

    private func doSearch() {
        guard let database = appModel.database else { return }
        didSearch = true
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

/// Each card contributes one entry. The default value is what the parent sees if no children
/// emit anything. The reduce function is how SwiftUI combines zero, one or many child
/// contributions into a single value.
/// Example:
/// 1. The desktop builds the 'tree', say cardViews a, b and c.
//private struct CardFramePrefKey: PreferenceKey {
//
//    static var defaultValue: [UUID: CGRect] = [:]
//
//    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
//        value.merge(nextValue(), uniquingKeysWith: { $1 })
//    }
//}
//
//private struct ReportCardFrame: ViewModifier {
//    let id: UUID
//    func body(content: Content) -> some View {
//        content.background(
//            GeometryReader { geo in
//                Color.clear.preference(
//                    key: CardFramePrefKey.self,
//                    value: [id: geo.frame(in: .named("desktop"))]
//                )
//            }
//        )
//    }
//}
//
//private extension View {
//    func reportCardFrame(id: UUID) -> some View {
//        modifier(ReportCardFrame(id: id))
//    }
//}

// MARK: - Desktop Context Menu
/// Desktop context menu as a computed property.
extension DesktopView {

    @ViewBuilder
    var desktopContextMenu: some View {
        let selectedCount = model.selectedIDs.count

        if selectedCount >= 2 {
            Button("Make Same Size") {
                model.makeSelectedSameSize()
            }

            Menu("Align") {
                Button("Left")   { model.alignSelected(.left) }
                Button("Right")  { model.alignSelected(.right) }
                Button("Top")    { model.alignSelected(.top) }
                Button("Bottom") { model.alignSelected(.bottom) }
            }

            Menu("Distribute") {
                Button("Horizontally") {
                    model.distributeSelected(.horizontal)
                }
                .disabled(selectedCount < 3)

                Button("Vertically") {
                    model.distributeSelected(.vertical)
                }
                .disabled(selectedCount < 3)
            }

            Divider()
        }

        Button("Add Person to Desktop...") {
            showingSearchSheet = true
        }
    }
}

/// Desktop context menu as a view.
extension DesktopView {

    private struct DesktopContextMenu: View {
        @Bindable var model: DesktopModel
        @Binding var showingSearchSheet: Bool

        var body: some View {
            let selectedCount = model.selectedIDs.count

            if selectedCount >= 2 {
                Button("Make Same Size") { model.makeSelectedSameSize() }

                Menu("Align") {
                    Button("Left")   { model.alignSelected(.left) }
                    Button("Right")  { model.alignSelected(.right) }
                    Button("Top")    { model.alignSelected(.top) }
                    Button("Bottom") { model.alignSelected(.bottom) }
                }

                Menu("Distribute") {
                    Button("Horizontally") { model.distributeSelected(.horizontal) }
                        .disabled(selectedCount < 3)
                    Button("Vertically") { model.distributeSelected(.vertical) }
                        .disabled(selectedCount < 3)
                }

                Divider()
            }

            Button("Add Person to Desktop...") { showingSearchSheet = true }
        }
    }
}
