import SwiftUI
import Combine

// ----------------------------------------------------------
// MARK: - Mock Data Model (GNode)
// ----------------------------------------------------------

final class GNode: Identifiable, ObservableObject {
    let id = UUID()
    var tag: String
    var value: String?
    @Published var children: [GNode] = []
    weak var parent: GNode?

    init(tag: String, value: String? = nil, children: [GNode] = []) {
        self.tag = tag
        self.value = value
        self.children = children
        for c in children { c.parent = self }
    }

    func addChild(_ node: GNode) {
        children.append(node)
        node.parent = self
    }

    func removeChild(_ node: GNode) {
        children.removeAll { $0.id == node.id }
    }

    func clone() -> GNode {
        let copy = GNode(tag: tag, value: value)
        copy.children = children.map { $0.clone() }
        for c in copy.children { c.parent = copy }
        return copy
    }

    func findNode(_ id: UUID) -> GNode? {
        if id == self.id { return self }
        for c in children {
            if let f = c.findNode(id) { return f }
        }
        return nil
    }
}

// ----------------------------------------------------------
// MARK: - Merge Model
// ----------------------------------------------------------

enum MergeProvenance: UInt8, Codable {
    case leftOnly, rightOnly, both, mixed
}

enum MergeMode { case manual, preMerged }

enum MergeAction {
    case insert(GNode, parent: GNode)
    case delete(GNode, from: GNode)
    case editTag(GNode, old: String, new: String)
    case editValue(GNode, old: String?, new: String?)
}

final class MergeUndoManager {
    private var undoStack: [MergeAction] = []
    private var redoStack: [MergeAction] = []

    func record(_ action: MergeAction) {
        undoStack.append(action)
        redoStack.removeAll()
    }

    func undo() -> MergeAction? { undoStack.popLast() }
    func redo() -> MergeAction? { redoStack.popLast() }
}

final class MergeSession: ObservableObject {
    let leftRoot: GNode
    let rightRoot: GNode
    @Published var mergedRoot: GNode
    @Published var provenanceMap: [UUID: MergeProvenance] = [:]
    let mode: MergeMode
    var undoManager = MergeUndoManager()

    init(left: GNode, right: GNode, merged: GNode,
         mode: MergeMode = .manual,
         provenance: [UUID: MergeProvenance] = [:]) {
        self.leftRoot = left
        self.rightRoot = right
        self.mergedRoot = merged
        self.mode = mode
        self.provenanceMap = provenance
    }
}

// ----------------------------------------------------------
// MARK: - MergeTreeView + NodeRow
// ----------------------------------------------------------

enum MergeTreeMode { case source(MergeProvenance), merged }

struct MergeTreeView: View {
    let title: String
    @ObservedObject var root: GNode
    let mode: MergeTreeMode
    @ObservedObject var session: MergeSession

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.headline)
                .padding(4)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    MergeNodeRow(node: root, mode: mode, session: session, level: 0)
                }
                .padding(4)
            }
        }
        .background(backgroundColor)
        .border(Color.gray.opacity(0.3))
    }

    private var backgroundColor: Color {
        switch mode {
        case .source(.leftOnly):  return Color.blue.opacity(0.05)
        case .source(.rightOnly): return Color.orange.opacity(0.05)
        default: return Color.clear
        }
    }
}

struct MergeNodeRow: View {
    @ObservedObject var node: GNode
    let mode: MergeTreeMode
    @ObservedObject var session: MergeSession
    let level: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack {
                Text(node.tag)
                    .fontWeight(.semibold)
                    .foregroundColor(colorFor(node))
                if let value = node.value {
                    Text(value)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if case .merged = mode {
                    Button {
                        if let p = node.parent {
                            p.removeChild(node)
                            session.undoManager.record(.delete(node, from: p))
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding(.leading, CGFloat(level) * 12)

            ForEach(node.children) { child in
                MergeNodeRow(node: child, mode: mode,
                             session: session, level: level + 1)
            }
        }
    }

    private func colorFor(_ node: GNode) -> Color {
        switch session.provenanceMap[node.id] {
        case .leftOnly:  return .blue
        case .rightOnly: return .orange
        case .both:      return .gray
        case .mixed:     return .green
        default:         return .primary
        }
    }
}

// ----------------------------------------------------------
// MARK: - MergeEditorView
// ----------------------------------------------------------

struct MergeEditorView: View {
    @ObservedObject var session: MergeSession

    var body: some View {
        HStack(spacing: 0) {
            MergeTreeView(title: "Source A",
                          root: session.leftRoot,
                          mode: .source(.leftOnly),
                          session: session)
            Divider()
            MergeTreeView(title: "Merged",
                          root: session.mergedRoot,
                          mode: .merged,
                          session: session)
            Divider()
            MergeTreeView(title: "Source B",
                          root: session.rightRoot,
                          mode: .source(.rightOnly),
                          session: session)
        }
        .toolbar {
            Button("Undo") { _ = session.undoManager.undo() }
            Button("Redo") { _ = session.undoManager.redo() }
        }
    }
}

// ----------------------------------------------------------
// MARK: - Demo Data + Entry Point
// ----------------------------------------------------------

@main
struct MergePrototypeApp: App {
    var body: some Scene {
        WindowGroup {
            MergeEditorView(session: demoSession())
                .frame(minWidth: 900, minHeight: 500)
        }
    }

    private func demoSession() -> MergeSession {
        // Left record
        let left = GNode(tag: "INDI")
        left.addChild(GNode(tag: "NAME", value: "John Doe"))
        left.addChild(GNode(tag: "BIRT", children: [
            GNode(tag: "DATE", value: "1 JAN 1900"),
            GNode(tag: "PLAC", value: "Boston")
        ]))

        // Right record
        let right = GNode(tag: "INDI")
        right.addChild(GNode(tag: "NAME", value: "John A. Doe"))
        right.addChild(GNode(tag: "BIRT", children: [
            GNode(tag: "DATE", value: "01 JAN 1900"),
            GNode(tag: "PLAC", value: "Boston, MA")
        ]))
        right.addChild(GNode(tag: "DEAT", children: [
            GNode(tag: "DATE", value: "5 MAY 1975")
        ]))

        // Start with empty merged record
        let merged = GNode(tag: "INDI")

        var provenance: [UUID: MergeProvenance] = [:]
        for n in flatten(left) { provenance[n.id] = .leftOnly }
        for n in flatten(right) { provenance[n.id] = .rightOnly }

        return MergeSession(left: left, right: right, merged: merged,
                            mode: .manual, provenance: provenance)
    }

    private func flatten(_ node: GNode) -> [GNode] {
        [node] + node.children.flatMap(flatten)
    }
}
