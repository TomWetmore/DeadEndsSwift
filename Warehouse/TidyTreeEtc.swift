//
//  TidyTree.swift
//  DeadEndsSwift
//
//


import SwiftUI
import DeadEndsLib

// MARK: - Public Types

/// A node placed by the tidy layout.
public struct PositionedNode<ID: Hashable>: Identifiable {
    public let id: ID
    public let position: CGPoint
    public let size: CGSize
}

public struct TidyConfig {
    public enum Orientation { case topDown, leftRight }

    /// Vertical gap between levels (in points, pre-scale).
    public var levelSeparation: CGFloat = 64
    /// Horizontal gap between siblings (in points, pre-scale).
    public var siblingSeparation: CGFloat = 24
    /// Minimum horizontal gap between adjacent subtrees (in points, pre-scale).
    public var subtreeSeparation: CGFloat = 32
    /// Layout orientation.
    public var orientation: Orientation = .topDown

    public init(levelSeparation: CGFloat = 64,
                siblingSeparation: CGFloat = 24,
                subtreeSeparation: CGFloat = 32,
                orientation: Orientation = .topDown) {
        self.levelSeparation = levelSeparation
        self.siblingSeparation = siblingSeparation
        self.subtreeSeparation = subtreeSeparation
        self.orientation = orientation
    }
}

// MARK: - Public API (generic tidy layout)

/// Computes a tidy layout for an arbitrary tree.
/// - Parameters:
///   - root: Root value of your tree.
///   - id: Closure returning a stable, Hashable ID for a value.
///   - children: Closure returning children for a value.
///   - size: Closure returning desired size for each node's box.
///   - config: Layout tweaks and orientation.
/// - Returns: Positioned nodes and the overall bounds of the layout.
public func tidyLayout<T, ID: Hashable>(
    root: T,
    id: (T) -> ID,
    children: (T) -> [T],
    size: (T) -> CGSize,
    config: TidyConfig = .init()
) -> (nodes: [PositionedNode<ID>], bounds: CGRect) {

    // Build non-generic LayoutNode tree and keep a mapping back to caller’s ID
    var idMap = [String: ID]() // LayoutNode.key -> external ID
    let ltRoot = buildLT(
        root,
        id: id,
        children: children,
        size: size,
        parent: nil,
        idMap: &idMap
    )

    firstWalk(ltRoot, cfg: config)

    // Second walk: finalize absolute x/y and collect bounds
    var placements: [(key: String, pos: CGPoint, size: CGSize)] = []
    var bounds = CGRect.null
    secondWalk(ltRoot, m: 0, depth: 0, cfg: config) { v, pos in
        let rect = CGRect(x: pos.x - v.size.width / 2, y: pos.y, width: v.size.width, height: v.size.height)
        bounds = bounds.union(rect)
        placements.append((v.key, pos, v.size))
    }

    // Normalize to positive coordinates and apply orientation swapping if needed.
    let dx = -bounds.minX
    let dy = -bounds.minY

    var out: [PositionedNode<ID>] = []
    out.reserveCapacity(placements.count)

    for (key, pos, sz) in placements {
        guard let extID = idMap[key] else { continue }
        let orientedPos: CGPoint
        let orientedBounds: CGRect
        switch config.orientation {
        case .topDown:
            orientedPos = CGPoint(x: pos.x + dx, y: pos.y + dy)
            orientedBounds = bounds.offsetBy(dx: dx, dy: dy)
        case .leftRight:
            // swap axes (x <- y, y <- x)
            orientedPos = CGPoint(x: pos.y + dy, y: pos.x + dx)
            orientedBounds = CGRect(x: 0, y: 0, width: bounds.height, height: bounds.width)
        }
        out.append(PositionedNode(id: extID, position: orientedPos, size: sz))
    }

    // Sort by y for stable ZStack layering (parents behind children)
    out.sort { $0.position.y < $1.position.y }

    let finalBounds: CGRect = {
        switch config.orientation {
        case .topDown:
            return bounds.offsetBy(dx: dx, dy: dy)
        case .leftRight:
            return CGRect(x: 0, y: 0, width: bounds.height, height: bounds.width)
        }
    }()

    return (out, finalBounds)
}

// MARK: - SwiftUI renderer (optional convenience)

/// A minimalist renderer that consumes `tidyLayout` output.
public struct FamilyTreeView<ID: Hashable, NodeView: View>: View {
    public let positioned: [PositionedNode<ID>]
    public let bounds: CGRect
    public var lineStrokeWidth: CGFloat = 1
    public var makeNodeView: (ID) -> NodeView
    public var parentOf: (ID) -> ID? // to draw simple parent links (optional heuristic)

    public init(positioned: [PositionedNode<ID>],
                bounds: CGRect,
                lineStrokeWidth: CGFloat = 1,
                parentOf: @escaping (ID) -> ID?,
                makeNodeView: @escaping (ID) -> NodeView) {
        self.positioned = positioned
        self.bounds = bounds
        self.lineStrokeWidth = lineStrokeWidth
        self.parentOf = parentOf
        self.makeNodeView = makeNodeView
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            // Edges (very simple: each node draws a line to its parent if present)
            ForEach(positioned) { node in
                if let pID = parentOf(node.id),
                   let parent = positioned.first(where: { $0.id == pID }) {
                    Path { path in
                        path.move(to: CGPoint(x: parent.position.x, y: parent.position.y + parent.size.height))
                        path.addLine(to: CGPoint(x: node.position.x, y: node.position.y))
                    }
                    .stroke(style: StrokeStyle(lineWidth: lineStrokeWidth))
                }
            }

            // Nodes
            ForEach(positioned) { n in
                makeNodeView(n.id)
                    .frame(width: n.size.width, height: n.size.height)
                    .position(x: n.position.x, y: n.position.y + n.size.height / 2)
            }
        }
        .frame(width: bounds.width, height: bounds.height, alignment: .topLeading)
    }
}

// MARK: - Internal layout machinery (non-generic)

/// Internal node used by the tidy algorithm. Keeps pointers required by RT.
final class LayoutNodeIsThisTheProblem {
    let key: String                     // stringified external ID
    var size: CGSize
    weak var parent: LayoutNode?
    var number: Int = 1                 // index among siblings (1-based)
    var children: [LayoutNode] = []

    // Reingold–Tilford state
    var prelim: CGFloat = 0
    var mod: CGFloat = 0
    var shift: CGFloat = 0
    var change: CGFloat = 0
    var thread: LayoutNode? = nil
    var ancestor: LayoutNode? = nil

    init(key: String, size: CGSize, parent: LayoutNode?, number: Int) {
        self.key = key
        self.size = size
        self.parent = parent
        self.number = number
        self.ancestor = self
    }

    /// Immediate left sibling if any.
    var leftSibling: LayoutNode? {
        guard let p = parent, number > 1 else { return nil }
        return p.children[number - 2]
    }
}

private func buildLT<T, ID: Hashable>(
    _ t: T,
    id: (T) -> ID,
    children: (T) -> [T],
    size: (T) -> CGSize,
    parent: LayoutNode? = nil,
    idMap: inout [String: ID]
) -> LayoutNode {
    let externalID = id(t)
    let key = String(describing: externalID)
    let number = (parent?.children.count ?? 0) + 1

    let node = LayoutNode(key: key, size: size(t), parent: parent, number: number)
    idMap[key] = externalID

    let kids = children(t)
    node.children = kids.map { child in
        buildLT(child, id: id, children: children, size: size, parent: node, idMap: &idMap)
    }
    return node
}

// MARK: Reingold–Tilford (Buchheim variant)

private func firstWalk(_ v: LayoutNode, cfg: TidyConfig) {
    if v.children.isEmpty {
        // Leaf: place to the right of left sibling
        if let ls = v.leftSibling {
            v.prelim = ls.prelim + 0.5 * (ls.size.width + v.size.width) + cfg.siblingSeparation
        } else {
            v.prelim = 0
        }
    } else {
        // Internal: layout children
        for c in v.children { firstWalk(c, cfg: cfg) }
        apportion(v, cfg: cfg)
        // Center parent above its children
        let left = v.children.first!.prelim
        let right = v.children.last!.prelim
        let mid = (left + right) / 2
        if let ls = v.leftSibling {
            v.prelim = ls.prelim + 0.5 * (ls.size.width + v.size.width) + cfg.siblingSeparation
            v.mod = v.prelim - mid
        } else {
            v.prelim = mid
        }
    }
}

private func apportion(_ v: LayoutNode, cfg: TidyConfig) {
    guard v.leftSibling != nil, let parent = v.parent, let firstChild = parent.children.first else { return }

    var vir = v
    var vil = v
    var vor = v.leftSibling!
    var vol = firstChild

    var sir = v.mod
    var sil = v.mod
    var sor = vor.mod
    var sol = vol.mod

    while let rNext = rightMost(vil), let lNext = leftMost(vor) {
        vil = rNext
        vor = lNext

        let distance = (vor.prelim + sor) - (vil.prelim + sil)
        + 0.5 * (vor.size.width + vil.size.width)
        + cfg.subtreeSeparation

        if distance > 0 {
            moveSubtree(wl: vol, wr: v, shift: distance)
            sil += distance
            sir += distance
        }

        sol += vol.mod
        sor += vor.mod
        sil += vil.mod
        sir += vir.mod

        if rightMost(vor) == nil { vol = leftMost(vol)! }
        if leftMost(vil) == nil { vir = rightMost(vir)! }
    }

    executeShifts(v)
}

private func moveSubtree(wl: LayoutNode, wr: LayoutNode, shift: CGFloat) {
    let subtrees = CGFloat(wr.number - wl.number)
    wr.change -= shift / subtrees
    wr.shift  += shift
    wl.change += shift / subtrees
    wr.prelim += shift
    wr.mod    += shift
}

private func executeShifts(_ v: LayoutNode) {
    var shift: CGFloat = 0
    var change: CGFloat = 0
    for child in v.children.reversed() {
        child.prelim += shift
        child.mod    += shift
        change       += child.change
        shift        += child.shift + change
    }
}

private func leftMost(_ v: LayoutNode) -> LayoutNode? { v.children.first ?? v.thread }
private func rightMost(_ v: LayoutNode) -> LayoutNode? { v.children.last ?? v.thread }

private func secondWalk(_ v: LayoutNode,
                        m: CGFloat,
                        depth: Int,
                        cfg: TidyConfig,
                        visit: (LayoutNode, CGPoint) -> Void) {
    let x = v.prelim + m
    let y = CGFloat(depth) * cfg.levelSeparation
    visit(v, CGPoint(x: x, y: y))
    for child in v.children {
        secondWalk(child, m: m + v.mod, depth: depth + 1, cfg: cfg, visit: visit)
    }
}
