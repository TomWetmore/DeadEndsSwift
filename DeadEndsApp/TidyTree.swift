//
//  TidyTree.swift
//  DeadEndsSwift
//
//  Last changed on 15 August 2025.
//
//  A minimal, generic Reingold–Tilford (Buchheim variant) tidy tree layout.
//
//  Public API:
//    - PositionedNode<ID>: positioned box + size
//    - TidyConfig: spacing + orientation
//    - tidyLayout(root:id:children:size:config:)
//        -> ([PositionedNode<ID>], bounds: CGRect)
//
//  Usage:
//    let (nodes, bounds) = tidyLayout(
//        root: myRoot,
//        id: { $0.id },
//        children: { $0.children },
//        size: { _ in CGSize(width: 220, height: 120) },
//        config: .init(levelSeparation: 110, siblingSeparation: 24, subtreeSeparation: 36)
//    )
//
//    // In SwiftUI later: position each node view at nodes[i].position with nodes[i].size
//

import Foundation
import CoreGraphics

// MARK: - Public Types

/// A node placed by the tidy layout.
public struct PositionedNode<ID: Hashable>: Identifiable {
    public let id: ID
    public let position: CGPoint  // top-left y coordinate for the node's top edge
    public let size: CGSize

    public init(id: ID, position: CGPoint, size: CGSize) {
        self.id = id
        self.position = position
        self.size = size
    }
}

/// Structure that sets the display properties of a Tidy Tree.
public struct TidyConfig {

    public enum Orientation { case topDown, leftRight }

    public var levelSeparation: CGFloat
    public var siblingSeparation: CGFloat
    public var subtreeSeparation: CGFloat
    public var orientation: Orientation

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

// MARK: - Public API

/// Computes a tidy layout for an arbitrary tree.
/// - Parameters:
///   - root: Root value of your tree.
///   - id: Closure returning a stable, Hashable ID for a value.
///   - children: Closure returning children for a value (must form a proper tree for this function).
///   - size: Closure returning desired size for each node's box.
///   - config: Layout tweaks and orientation.
/// - Returns: Positioned nodes and the overall bounds of the layout in the chosen orientation.
public func tidyLayout<T, ID: Hashable>(
    root: T,
    id: (T) -> ID,
    children: (T) -> [T],
    size: (T) -> CGSize,
    config: TidyConfig = .init()
) -> (nodes: [PositionedNode<ID>], bounds: CGRect) {

    // 1) Build a non-generic layout tree, keeping a mapping back to the caller’s IDs.
    var idMap = [String: ID]() // LayoutNode.key -> external ID
    let ltRoot = buildLayoutTree(root, id: id, children: children, size: size, parent: nil, idMap: &idMap)

    // 2) First pass: compute prelim/mod values.
    firstWalk(ltRoot, cfg: config)

    // 3) Second pass: compute absolute positions + raw bounds (before orientation swap/normalization).
    var placements: [(key: String, pos: CGPoint, size: CGSize)] = []
    var rawBounds = CGRect.null
    secondWalk(ltRoot, m: 0, depth: 0, cfg: config) { v, pos in
        // pos is the node center x and top y (consistent with RT derivation here).
        let rect = CGRect(x: pos.x - v.size.width / 2, y: pos.y, width: v.size.width, height: v.size.height)
        rawBounds = rawBounds.union(rect)
        placements.append((v.key, pos, v.size))
    }

    if placements.isEmpty {
        return ([], .zero)
    }

    // 4) Normalize to positive coordinates and apply orientation if needed.
    let dx = -rawBounds.minX
    let dy = -rawBounds.minY

    var out: [PositionedNode<ID>] = []
    out.reserveCapacity(placements.count)

    switch config.orientation {
    case .topDown:
        for (key, pos, sz) in placements {
            guard let extID = idMap[key] else { continue }
            let finalPos = CGPoint(x: pos.x + dx, y: pos.y + dy)
            out.append(PositionedNode(id: extID, position: finalPos, size: sz))
        }
    case .leftRight:
        // Swap axes: x' <- y, y' <- x
        for (key, pos, sz) in placements {
            guard let extID = idMap[key] else { continue }
            let finalPos = CGPoint(x: pos.y + dy, y: pos.x + dx)
            out.append(PositionedNode(id: extID, position: finalPos, size: sz))
        }
    }

    // Keep a stable paint order (parents first).
    out.sort { $0.position.y < $1.position.y }

    // Compute final bounds in the oriented space.
    let finalBounds: CGRect = {
        switch config.orientation {
        case .topDown:
            return rawBounds.offsetBy(dx: dx, dy: dy)
        case .leftRight:
            // When swapping axes, width/height are swapped.
            return CGRect(x: 0, y: 0, width: rawBounds.height, height: rawBounds.width)
        }
    }()

    return (out, finalBounds)
}

// MARK: - Internal layout machinery

/// Internal node used by the tidy algorithm. Keeps pointers required by RT.
/*private*/ final class LayoutNode {
    let key: String                  // stringified external ID
    var size: CGSize
    weak var parent: LayoutNode?
    var number: Int = 1              // index among siblings (1-based)
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

@inline(__always)
private func buildLayoutTree<T, ID: Hashable>(
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
        buildLayoutTree(child, id: id, children: children, size: size, parent: node, idMap: &idMap)
    }
    return node
}

// MARK: Reingold–Tilford (Buchheim variant)

@inline(__always)
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

@inline(__always)
private func apportion(_ v: LayoutNode, cfg: TidyConfig) {
    guard v.leftSibling != nil,
          let parent = v.parent,
          let firstChild = parent.children.first else { return }

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

        let distance =
            (vor.prelim + sor) - (vil.prelim + sil)
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

@inline(__always)
private func moveSubtree(wl: LayoutNode, wr: LayoutNode, shift: CGFloat) {
    let subtrees = CGFloat(wr.number - wl.number)
    wr.change -= shift / subtrees
    wr.shift  += shift
    wl.change += shift / subtrees
    wr.prelim += shift
    wr.mod    += shift
}

@inline(__always)
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

@inline(__always)
private func leftMost(_ v: LayoutNode) -> LayoutNode? { v.children.first ?? v.thread }
@inline(__always)
private func rightMost(_ v: LayoutNode) -> LayoutNode? { v.children.last ?? v.thread }

@inline(__always)
private func secondWalk(
    _ v: LayoutNode,
    m: CGFloat,
    depth: Int,
    cfg: TidyConfig,
    visit: (LayoutNode, CGPoint) -> Void
) {
    let x = v.prelim + m
    let y = CGFloat(depth) * cfg.levelSeparation
    visit(v, CGPoint(x: x, y: y))
    for child in v.children {
        secondWalk(child, m: m + v.mod, depth: depth + 1, cfg: cfg, visit: visit)
    }
}
