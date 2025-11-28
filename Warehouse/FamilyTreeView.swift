//
//  FamilyTreeView.swift
//  DeadEndsSwift
//
//  Created by Thomas Wetmore on 8/8/25.
//  Coalesced by ChatGPT on 8/8/25.
//
//  

import SwiftUI

// MARK: - PersonCard (experiment component)

struct PersonCardView: View {
    // Display
    let name: String
    let subtitle: String?

    // Spouses to cycle through. Use empty array if none.
    let spouses: [String]

    // Presentation flags (these affect only visuals in this component)
    @Binding var showParents: Bool
    @Binding var showSiblings: Bool
    @Binding var showChildren: Bool

    // Current spouse selection index; -1 means "none selected".
    @Binding var spouseIndex: Int

    // Actions (bubble up to the hosting view; plug into real model later).
    var onToggleParents: (() -> Void)?
    var onToggleSiblings: (() -> Void)?
    var onCycleSpouse:   (() -> Void)?
    var onToggleChildren: (() -> Void)?

    // Visual constants for quick iteration
    var size: CGSize = CGSize(width: 200, height: 110)
    var cornerRadius: CGFloat = 14

    var body: some View {
        ZStack {
            // Card base
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.background)
                .shadow(radius: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(.quaternary, lineWidth: 1)
                )

            // Content
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

                // Spouse readout (if selected)
                if let spouse = currentSpouseName {
                    Text("Spouse: \(spouse)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .padding(.top, 2)
                }

                // Tiny status row for quick feedback while experimenting
                HStack(spacing: 10) {
                    statusTag(showParents, label: "Parents")
                    statusTag(showSiblings, label: "Siblings")
                    statusTag(spouseIndex >= 0, label: "Spouse")
                    statusTag(showChildren, label: "Children")
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            // Side buttons (top/left/right/bottom)
            overlayButton(systemName: showParents ? "person.badge.plus" : "person.badge.minus",
                          hint: showParents ? "Remove parents" : "Add parents",
                          alignment: .top,
                          action: { onToggleParents?(); showParents.toggle() })

            overlayButton(systemName: showSiblings ? "person.2.fill" : "person.2",
                          hint: "Toggle siblings",
                          alignment: .leading,
                          action: { onToggleSiblings?(); showSiblings.toggle() })

            overlayButton(systemName: "heart.text.square",
                          hint: "Cycle spouse",
                          alignment: .trailing,
                          action: cycleSpouse)

            overlayButton(systemName: showChildren ? "figure.child.circle.fill" : "figure.child.circle",
                          hint: "Toggle children",
                          alignment: .bottom,
                          action: { onToggleChildren?(); showChildren.toggle() })
        }
        .frame(width: size.width, height: size.height)
        .animation(.snappy, value: showParents)
        .animation(.snappy, value: showSiblings)
        .animation(.snappy, value: showChildren)
        .animation(.snappy, value: spouseIndex)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Person card for \(name)")
    }

    // MARK: Helpers

    private var currentSpouseName: String? {
        guard spouseIndex >= 0, spouseIndex < spouses.count else { return nil }
        return spouses[spouseIndex]
    }

    private func cycleSpouse() {
        onCycleSpouse?()
        if spouses.isEmpty { return }
        // -1 (none) → 0 → 1 → ... → last → back to -1
        let last = spouses.count - 1
        if spouseIndex < 0 { spouseIndex = 0 }
        else if spouseIndex < last { spouseIndex += 1 }
        else { spouseIndex = -1 }
    }

    @ViewBuilder
    private func overlayButton(systemName: String,
                               hint: String,
                               alignment: Alignment,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .imageScale(.medium)
                .padding(6)
        }
        .buttonStyle(.borderless)
        .help(hint)
        .background(
            Circle().fill(.thinMaterial)
                .overlay(Circle().stroke(.quaternary, lineWidth: 0.5))
        )
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
        .contentShape(Rectangle())
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

// MARK: - Preview harness (stateful wrapper so you can poke at it)

private struct PersonCardPreviewWrapper: View {
    @State var showParents = false
    @State var showSiblings = false
    @State var showChildren = false
    @State var spouseIndex: Int = -1 // start with none

    let spouses: [String] = ["Alexandra", "Jamie", "Pat"]

    var body: some View {
        VStack(spacing: 24) {
            PersonCardView(
                name: "John Q. Example",
                subtitle: "b. 1947 – d. 2020",
                spouses: spouses,
                showParents: $showParents,
                showSiblings: $showSiblings,
                showChildren: $showChildren,
                spouseIndex: $spouseIndex,
                onToggleParents: { print("toggle parents") },
                onToggleSiblings: { print("toggle siblings") },
                onCycleSpouse: { print("cycle spouse") },
                onToggleChildren: { print("toggle children") }
            )

            // Quick controls to test from the preview pane
            controlPanel
        }
        .padding(20)
        .frame(maxWidth: 500)
    }

    private var controlPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview Controls").font(.headline)
            Toggle("Show Parents", isOn: $showParents)
            Toggle("Show Siblings", isOn: $showSiblings)
            Toggle("Show Children", isOn: $showChildren)
            HStack {
                Text("Spouse:")
                Button("Cycle") {
                    if spouses.isEmpty { return }
                    if spouseIndex < 0 { spouseIndex = 0 }
                    else if spouseIndex < spouses.count - 1 { spouseIndex += 1 }
                    else { spouseIndex = -1 }
                }
                Text(spouseIndex >= 0 ? spouses[spouseIndex] : "None")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(.thinMaterial))
    }
}

#Preview("Person Card – Interactive") {
    PersonCardPreviewWrapper()
        .previewLayout(.sizeThatFits)
}

#Preview("Compact") {
    PersonCardView(
        name: "Jane Doe",
        subtitle: nil,
        spouses: [],
        showParents: .constant(false),
        showSiblings: .constant(false),
        showChildren: .constant(false),
        spouseIndex: .constant(-1)
    )
    .previewLayout(.sizeThatFits)
    .padding(10)
}

#Preview("With Spouses") {
    PersonCardView(
        name: "Chris Smith",
        subtitle: "b. 1902",
        spouses: ["Taylor", "Jordan"],
        showParents: .constant(true),
        showSiblings: .constant(false),
        showChildren: .constant(true),
        spouseIndex: .constant(0)
    )
    .previewLayout(.sizeThatFits)
    .padding(10)
}

