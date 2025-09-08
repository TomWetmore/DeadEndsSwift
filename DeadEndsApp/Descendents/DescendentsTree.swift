//
//  DescendentsTree.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 20 August 2025.
//  Last changed on 21 August 2025.
//
//  Still in experimental form. Intended to show family trees as graphs.

import Foundation
import DeadEndsLib

/// Descendancy trees have two node types, Person and Union.
enum EntityKind { case person(String), union(String) }

/// Entity Node (Person or Union) for Descendency charts. Children of persons are unions and children of unions
/// are persons.
struct EntityNode {
    let kind: EntityKind
    var children: [EntityNode] = []
}

/// Build a descendants tree from a given person to a given depth.
func buildDescendantsTree(from person: GedcomNode, index: RecordIndex, depth: Int) -> EntityNode? {
    var vpersons: Set<String> = []
    var vunions: Set<String> = []
    return buildDescendantsTree(from: person, index: index, depth: depth, vpersons: &vpersons, vunions: &vunions)
}

/// Recursive function that builds descendant tree.
/// - Parameters:
///   - person: root person record
///   - index: GEDCOM record index
///   - depth: descendant generations to include (0 = just the person)
///   - vpersons/vunions: visited sets to prevent cycles/duplication
func buildDescendantsTree(from person: GedcomNode, index: RecordIndex, depth: Int,
                            vpersons: inout Set<String>, vunions: inout Set<String>) -> EntityNode? {

    // Do not include the same person more than once.
    guard let pkey = person.key, vpersons.insert(pkey).inserted else { return nil }
    var pnode = EntityNode(kind: .person(pkey))
    guard depth > 0 else { return pnode }

    // Get the keys of the families the person is a spouse in.
    let fkeys = person.children(withTag: "FAMS").compactMap { $0.value }
    var unionChildren: [EntityNode] = []

    // Loop over each family as spouse in the database.
    for fkey in fkeys {
        // Do not include the same family more than once.
        guard vunions.insert(fkey).inserted, let fam = index[fkey] else { continue }

        var unode = EntityNode(kind: .union(fkey))

        // Get the keys of all children in the family.
        let ckeys = fam.children(withTag: "CHIL").compactMap { $0.value }
        unode.children = ckeys.compactMap { cid in
            guard let child = index[cid] else { return nil }
            return buildDescendantsTree(from: child, index: index, depth: depth - 1,
                                          vpersons: &vpersons, vunions: &vunions)
        }
        unionChildren.append(unode)
    }

    // Attach zero or more unions under the person
    pnode.children = unionChildren
    return pnode
}

func showDescendantsTree(_ tree: EntityNode, index: RecordIndex) {
    showDescendantsTree(tree, indent: "", index: index)
}

private func showDescendantsTree(_ tree: EntityNode, indent: String, index: RecordIndex) {
    switch tree.kind {
    case .person(let pid):
        if let person = index[pid] {
            print("\(indent)\(person.displayName())")
        } else {
            print("\(indent)\(pid) (not found)")
        }

    case .union(let fid):
        if let fam = index[fid] {
            // Look up spouses
            let spouseIDs = [fam.child(withTag: "HUSB")?.value,
                             fam.child(withTag: "WIFE")?.value].compactMap { $0 }

            let spouseNames = spouseIDs.compactMap { sid in
                index[sid]?.displayName()
            }

            if spouseNames.isEmpty {
                print("\(indent)\(fid)")
            } else {
                // Join names if both known
                print("\(indent)\(spouseNames.joined(separator: " & "))")
            }
        } else {
            print("\(indent)\(fid) (not found)")
        }
    }

    for child in tree.children {
        showDescendantsTree(child, indent: indent + "  ", index: index)
    }
}

//struct LayoutNode {
//    let key: String
//    var size: CGSize
//    var children: [LayoutNode] = []
//}

//func projectForTidy(_ n: PNode, measure: (String)->CGSize) -> LayoutNode {
//    var ln = LayoutNode(key: n.id, size: measure(n.id))
//    ln.children = n.children.map { projectForTidy($0, measure: measure) }
//    return ln
//}
//
//// For Person/Union:
//func projectForTidyPU(_ n: LNode, measurePerson: (String)->CGSize, measureUnion: (String)->CGSize) -> LayoutNode {
//    let size: CGSize = {
//        switch n.kind {
//        case .person(let id): return measurePerson(id)
//        case .spouse(let fid): return measureUnion(fid)
//        }
//    }()
//    var ln = LayoutNode(key: nodeKey(n), size: size)
//    ln.children = n.children.map { projectForTidyPU($0, measurePerson: measurePerson, measureUnion: measureUnion) }
//    return ln
//}

/// Pretty-prints a LayoutNode tree with x/y positions.
/// Assumes you have a LayoutNode with .id, .children, and layout results
/// (maybe stored in dictionaries or as properties).
//func dumpLayoutTree(
//    _ node: LayoutNode,
//    positions: [EntityID: (x: Int, y: Int)],
//    indent: String = ""
//) {
//    guard let pos = positions[node.id] else {
//        print("\(indent)\(node.id) (no pos)")
//        return
//    }
//
//    print("\(indent)\(node.id) @ (\(pos.x), \(pos.y))")
//
//    for child in node.children {
//        dumpLayoutTree(child, positions: positions, indent: indent + "  ")
//    }
//}
//
//
//// ASCII box output for testing.
//
//// MARK: - Tiny ASCII renderer for tidy layouts
//
//// 1) Minimal IDs (adapt to your EntityID)
//enum EID: Hashable, CustomStringConvertible {
//    case person(String), spouse(String)
//    var description: String {
//        switch self {
//        case .person(let s): return "P:\(s)"
//        case .spouse(let s):  return "U:\(s)"
//        }
//    }
//}
//
//// 2) Minimal layout tree (what tidy gave you)
////struct LayoutNode {
////    let id: EID
////    var children: [LayoutNode] = []
////}
//
//// 3) ASCII renderer
//struct AsciiRenderer {
//    // Box and grid “scale” (characters per x, lines per y)
//    let boxWidth = 11           // interior label width ~ 9
//    let boxHeight = 3           // 3 lines tall
//    let xScale = 14             // horizontal spacing between centers
//    let yScale = 5              // vertical spacing between centers
//
//    // Characters (switch to ASCII fallback if your terminal lacks Unicode)
//    let H: Character = "─", V: Character = "│"
//    let TL: Character = "┌", TR: Character = "┐", BL: Character = "└", BR: Character = "┘"
//    let T: Character = "┬", B: Character = "┴", L: Character = "├", R: Character = "┤"
//    let cross: Character = "┼"
//
//    func render(root: LayoutNode,
//                positions: [EID:(x:Int,y:Int)],
//                label: (EID)->String = { "\($0)" }) -> String
//    {
//        // Compute canvas extents from positions
//        guard !positions.isEmpty else { return "" }
//        let xs = positions.values.map{$0.x}, ys = positions.values.map{$0.y}
//        let minX = xs.min()!, maxX = xs.max()!
//        let minY = ys.min()!, maxY = ys.max()!
//
//        // Center-to-canvas mapping
//        func cx(_ x:Int) -> Int { (x - minX) * xScale + xScale/2 }
//        func cy(_ y:Int) -> Int { (y - minY) * yScale + yScale/2 }
//
//        // Canvas size (leave margins)
//        let width  = (maxX - minX + 1) * xScale + xScale
//        let height = (maxY - minY + 1) * yScale + yScale
//        var grid = Array(repeating: Array(repeating: " ", count: width), count: height)
//
//        // Helpers to draw primitives
//        func put(_ ch: Character, _ x:Int, _ y:Int) {
//            guard y >= 0 && y < height && x >= 0 && x < width else { return }
//            grid[y][x] = ch
//        }
//        func hLine(_ x1:Int, _ x2:Int, _ y:Int) {
//            if x1 <= x2 {
//                for x in x1...x2 { put(H, x, y) }
//            } else {
//                for x in x2...x1 { put(H, x, y) }
//            }
//        }
//        func vLine(_ y1:Int, _ y2:Int, _ x:Int) {
//            if y1 <= y2 {
//                for y in y1...y2 { put(V, x, y) }
//            } else {
//                for y in y2...y1 { put(V, x, y) }
//            }
//        }
//        func drawBox(centerX:Int, centerY:Int, text:String) {
//            let w = boxWidth, h = boxHeight
//            let left = centerX - w/2, right = centerX + w/2
//            let top  = centerY - h/2, bottom = centerY + h/2
//            // frame
//            put(TL, left, top); put(TR, right, top)
//            put(BL, left, bottom); put(BR, right, bottom)
//            hLine(left+1, right-1, top); hLine(left+1, right-1, bottom)
//            vLine(top+1, bottom-1, left); vLine(top+1, bottom-1, right)
//            // label (truncate or center)
//            let inner = max(0, w-2)
//            let truncated = String(text.prefix(inner))
//            let padLeft = max(0, (inner - truncated.count)/2)
//            let labelLine = top + h/2
//            for (i,ch) in truncated.enumerated() { put(ch, left+1+padLeft+i, labelLine) }
//        }
//        func drawEdge(from parent: (Int,Int), to child: (Int,Int)) {
//            // Connect bottom center of parent box to top center of child box
//            let (px,py) = parent
//            let (cx,cy_) = child
//            let pBotY = py + boxHeight/2
//            let cTopY = cy_ - boxHeight/2
//            let midY = (pBotY + cTopY)/2
//            // vertical from parent down to mid
//            vLine(pBotY+1, midY, px)
//            // horizontal elbow to child's column
//            hLine(px, cx, midY)
//            // vertical from mid to child top
//            vLine(midY, cTopY-1, cx)
//            // tee into child box top
//            put(T, cx, cTopY)
//            // tee from parent bottom
//            put(B, px, pBotY)
//        }
//
//        // DFS draw: edges first so boxes overwrite junction artifacts
//        func drawSubtree(_ n: LayoutNode) {
//            guard let p = positions[n.id] else { return }
//            let pc = (cx(p.x), cy(p.y))
//            for c in n.children {
//                if let cp = positions[c.id] {
//                    drawEdge(from: pc, to: (cx(cp.x), cy(cp.y)))
//                }
//            }
//            drawBox(centerX: pc.0, centerY: pc.1, text: label(n.id))
//            for c in n.children { drawSubtree(c) }
//        }
//
//        drawSubtree(root)
//        return grid.map { String($0) }.joined(separator: "\n")
//    }
//}
