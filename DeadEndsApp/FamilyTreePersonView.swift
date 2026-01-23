//
//  FamilyTreePersonView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 14 August 2025.
//

import SwiftUI

// MARK: - Semicircle infrastructure (local)

private enum EdgePlacement { case top, left, right, bottom }

/// A half-disk oriented to an edge; flat side faces the card, round side outward.
private struct Semicircle: Shape {
    let edge: EdgePlacement

    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) / 2
        let c = CGPoint(x: rect.midX, y: rect.midY)

        /// Define degree angle pairs for each semicircle.
        let (startDeg, endDeg): (CGFloat, CGFloat) = {
            switch edge {
            case .top:     return (180, 360) // lower half
            case .bottom:  return (0,   180) // upper half
            case .left:    return (90,  270) // right half
            case .right:   return (270,  90) // left half
            }
        }()

        func pt(_ deg: CGFloat) -> CGPoint {
            let rad = deg * .pi / 180
            return CGPoint(x: c.x + r * cos(rad), y: c.y + r * sin(rad))
        }

        let start = Angle(degrees: startDeg)
        let end   = Angle(degrees: endDeg)
        let p0 = pt(startDeg)

        var p = Path()
        p.move(to: p0)
        p.addArc(center: c, radius: r, startAngle: start, endAngle: end, clockwise: false)
        p.addLine(to: p0)
        p.closeSubpath()
        return p
    }
}

private struct SemicircleButton: View {
    let edge: EdgePlacement
    let radius: CGFloat
    //let systemName: String
    let active: Bool
    let hint: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Semicircle(edge: edge)
                    .fill(active ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08))
                    .overlay(Semicircle(edge: edge).stroke(.quaternary, lineWidth: 1))
                    .shadow(radius: 1, y: 0.5)

//                Image(systemName: systemName)
//                    .imageScale(.medium)
//                    .font(.system(size: 13, weight: .semibold))
//                    .foregroundStyle(active ? .primary : .secondary)
//                    .offset(iconOffsetTowardCard)
            }
            .frame(width: radius * 2, height: radius * 2)
        }
        .buttonStyle(.plain)
        .help(hint)
        .accessibilityLabel(Text(hint))
        .accessibilityAddTraits(.isButton)
    }

    private var iconOffsetTowardCard: CGSize {
        switch edge {
        case .top:    return .init(width: 0,              height:  radius * 0.25)
        case .bottom: return .init(width: 0,              height: -radius * 0.25)
        case .left:   return .init(width:  radius * 0.25, height: 0)
        case .right:  return .init(width: -radius * 0.25, height: 0)
        }
    }
}

/// Centered person card with four semicircle controls.
/// Bind this view into your FamilyTree host; it owns its own simple UI state for now.
struct FamilyTreePersonView: View {
    // Inputs from caller (map these from your Gedcom model upstream)
    let name: String
    let subtitle: String?
    let spouses: [String]

    // Local UI state (replace with bindings/actions later)
    @State private var showParents = false
    @State private var showSiblings = false
    @State private var showChildren = false
    @State private var spouseIndex = -1    // -1 == none selected

    // Visual tuning
    private let cardSize = CGSize(width: 200, height: 250)
    private let cornerRadius: CGFloat = 14
    private let buttonRadius: CGFloat = 16

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            // Main card
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.background)
                .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(.quaternary, lineWidth: 1))
                .shadow(radius: 2)
                .frame(width: cardSize.width, height: cardSize.height)
                .overlay(cardContent) // text + status inside

            // Parents link on top.
            SemicircleButton(
                edge: .top, radius: buttonRadius,
                //systemName: showParents ? "person.badge.minus" : "person.badge.plus",
                active: showParents,
                hint: showParents ? "Remove parents" : "Add parents",
                action: { showParents.toggle() }
            )
            .offset(x: 0, y: -(cardSize.height / 2))

            // Siblings link on left.
            SemicircleButton(
                edge: .left, radius: buttonRadius,
                //systemName: showSiblings ? "person.2.fill" : "person.2",
                active: showSiblings,
                hint: "Toggle siblings",
                action: { showSiblings.toggle() }
            )
            .offset(x: -(cardSize.width / 2), y: 0)

            // Spouse link on right.
            SemicircleButton(
                edge: .right, radius: buttonRadius,
                //systemName: spouseIndex >= 0 ? "heart.text.square.fill" : "heart.text.square",
                active: spouseIndex >= 0,
                hint: "Cycle spouse",
                action: cycleSpouse
            )
            .offset(x: (cardSize.width / 2), y: 0)

            // Children link on bottom.
            SemicircleButton(
                edge: .bottom, radius: buttonRadius,
                //systemName: showChildren ? "figure.child.circle.fill" : "figure.child.circle",
                active: showChildren,
                hint: "Toggle children",
                action: { showChildren.toggle() }
            )
            .offset(x: 0, y: (cardSize.height / 2))
        }
        // Enlarge the container so outside buttons are tappable
        .frame(
            width: cardSize.width + 2 * (buttonRadius + 2),
            height: cardSize.height + 2 * (buttonRadius + 2)
        )
        .animation(.snappy, value: showParents)
        .animation(.snappy, value: showSiblings)
        .animation(.snappy, value: showChildren)
        .animation(.snappy, value: spouseIndex)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Person card for \(name)")
        .onAppear {  // DEBUG.
            for spouse in spouses {
                print(spouse)
            }
        }
    }

    // MARK: - Subviews / Helpers

    @ViewBuilder
    private var cardContent: some View {
        VStack(spacing: 6) {
            Text(name)
                .font(.headline)
                .lineLimit(1)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let spouse = currentSpouseName {
                Text("Spouse: \(spouse)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.top, 2)
            }

//            HStack(spacing: 10) {
//                statusTag(showParents, label: "Parents")
//                statusTag(showSiblings, label: "Siblings")
//                statusTag(currentSpouseName != nil, label: "Spouse")
//                statusTag(showChildren, label: "Children")
//            }
//            .padding(.top, 4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private var currentSpouseName: String? {
        guard spouseIndex >= 0, spouseIndex < spouses.count else { return nil }
        return spouses[spouseIndex]
    }

    private func cycleSpouse() {
        guard !spouses.isEmpty else { return }
        let last = spouses.count - 1
        if spouseIndex < 0 { spouseIndex = 0 }
        else if spouseIndex < last { spouseIndex += 1 }
        else { spouseIndex = -1 }
    }

    @ViewBuilder
    private func statusTag(_ on: Bool, label: String) -> some View {
        Text(label)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(on ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
            .clipShape(Capsule())
    }
}
