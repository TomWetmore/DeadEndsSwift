//
//  UnifiedPersonView.swift
//  DeadEndsApp
//
//  Created by Thomas Wetmore on 30 August 2025.
//  Last changed on 30 August 2025.
//

import SwiftUI
import DeadEndsLib

/// Protocol for Persons that are renderable with the XXXXX View defined below.
//protocol PersonRenderable {
//    var id: String { get }
//    var sex: SexType? { get }
//    var rawName: String? { get }
//    var rawBirth: (date: String?, place: String?)? { get }
//    var rawDeath: (date: String?, place: String?)? { get }
//}
//
///// Extension to GedcomNode that implements PersonRenderable.
//extension GedcomNode: PersonRenderable {
//
//    var id: String { key ?? ObjectIdentifier(self as AnyObject).debugDescription }
//    var sex: SexType? { sexOf() }
//    var rawName: String? { child(withTag: "NAME")?.value }
//    var rawBirth: (date: String?, place: String?)? {
//        let birth = child(withTag: "BIRT")
//        return (birth?.child(withTag: "DATE")?.value, birth?.child(withTag: "PLAC")?.value)
//    }
//    var rawDeath: (date: String?, place: String?)? {
//        let death = child(withTag: "DEAT")
//        return (death?.child(withTag: "DATE")?.value, death?.child(withTag: "PLAC")?.value)
//    }
//}

// MARK: - Config and strategies

struct PersonViewConfig {
    enum Style { case row, tile, chip }
    enum NameFormat { case rawGedcom, natural, surnameCaps, surnameFirst, truncated(Int) }
    struct EventOptions: OptionSet {
        let rawValue: Int
        static let none     = EventOptions([])
        static let dates    = EventOptions(rawValue: 1 << 0)
        static let places   = EventOptions(rawValue: 1 << 1)
        static let both: EventOptions = [.dates, .places]
    }
    enum HitBehavior { case none, tap(() -> Void), custom(GestureMask) }

    var style: Style = .row
    var nameFormat: NameFormat = .asGedcom
    var events: EventOptions = .none
    var foreground: Color? = nil
    var background: Color? = nil
    var isEmphasized: Bool = false
    var hitBehavior: HitBehavior = .none

    // Injected strategies (can be swapped per screen)
    var nameFormatter: (Person, NameFormat) -> String = DefaultFormatters.name
    var dateFormatter: (String) -> String = DefaultFormatters.date
    var placeFormatter: (String) -> String = DefaultFormatters.place
}

enum DefaultFormatters {
    static func name(_ p: Person, _ fmt: PersonViewConfig.NameFormat) -> String {
        let raw = p.rawName ?? "(no name)"
        func split(_ s: String) -> (given: String, surname: String, suffix: String?) {
            let parts = s.components(separatedBy: "/")
            switch parts.count {
            case 3: return (parts[0].trimmingCharacters(in: .whitespaces),
                            parts[1],
                            parts[2].trimmingCharacters(in: .whitespaces).isEmpty ? nil : parts[2].trimmingCharacters(in: .whitespaces))
            case 2: return (parts[0].trimmingCharacters(in: .whitespaces), parts[1], nil)
            default: return (s, "", nil)
            }
        }
        let (given, surname, suffix) = split(raw)
        switch fmt {
        case .asGedcom:
            return surname.isEmpty ? raw : [given, surname, suffix].compactMap{$0}.joined(separator: " ")
        case .surnameCaps:
            let name = surname.isEmpty ? raw : [given, surname.uppercased(), suffix].compactMap{$0}.joined(separator: " ")
            return name
        case .surnameFirst:
            guard !surname.isEmpty else { return raw }
            let base = "\(surname), \(given)"
            return suffix.map { base + " " + $0 } ?? base
        case .truncated(let n):
            let s = surname.isEmpty ? raw : [given, surname, suffix].compactMap{$0}.joined(separator: " ")
            return s.count <= n ? s : String(s.prefix(n-1)) + "…"
        }
    }
    static func date(_ s: String) -> String {
        // Swap in your GEDCOM-date normalization here (abt/bef/aft, etc.)
        s
    }
    static func place(_ s: String) -> String {
        // Apply your simplification/standardization here
        s
    }
}

// MARK: - Core view

struct CorePersonView<P: PersonRenderable>: View {
    let person: P
    var config: PersonViewConfig = .init()

    @ViewBuilder private func icon() -> some View {
        let symbol: String = {
            switch person.sex ?? .unknown {
            case .male: "♂"
            case .female: "♀"
            case .unknown: "∙"
            }
        }()
        Text(symbol)
            .font(.system(size: 16))
            .baselineOffset(5)
            .opacity(0.9)
    }

    @ViewBuilder private func nameLabel() -> some View {
        Text(config.nameFormatter(person, config.nameFormat))
            .font(config.style == .chip ? .footnote.weight(.semibold) : .body.weight(.medium))
            .lineLimit(1)
            .truncationMode(.tail)
    }

    @ViewBuilder private func eventsLabel() -> some View {
        if config.events.isEmpty { EmptyView() }
        else {
            let b = person.rawBirth
            let d = person.rawDeath
            HStack(spacing: 6) {
                if config.events.contains(.dates), let bd = b?.date {
                    Text("• \(config.dateFormatter(bd))").foregroundStyle(.secondary)
                }
                if config.events.contains(.dates), let dd = d?.date {
                    Text("– \(config.dateFormatter(dd))").foregroundStyle(.secondary)
                }
                if config.events.contains(.places), let bp = b?.place {
                    Text("• \(config.placeFormatter(bp))").foregroundStyle(.secondary)
                }
                if config.events.contains(.places), let dp = d?.place {
                    Text("– \(config.placeFormatter(dp))").foregroundStyle(.secondary)
                }
            }
            .font(.caption)
        }
    }

    @ViewBuilder var body: some View {
        let fg = config.foreground
        let bg = config.background

        Group {
            switch config.style {
            case .row:
                HStack(spacing: 6) {
                    icon()
                    VStack(alignment: .leading, spacing: 2) {
                        nameLabel()
                        eventsLabel()
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 4)
                .foregroundStyle(fg ?? Color.primary)
                .background(bg ?? .clear)

            case .tile:
                VStack(spacing: 6) {
                    icon()
                    nameLabel()
                    eventsLabel()
                }
                .padding(10)
                .frame(minWidth: 120)
                .background((bg ?? Color(.red)).opacity(config.isEmphasized ? 1 : 0.7))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    if config.isEmphasized {
                        RoundedRectangle(cornerRadius: 12).stroke((fg ?? .primary).opacity(0.2))
                    }
                }
                .foregroundStyle(fg ?? .primary)

            case .chip:
                HStack(spacing: 6) {
                    icon()
                    nameLabel()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((bg ?? Color(.tertiarySystemFill)))
                .clipShape(Capsule())
                .foregroundStyle(fg ?? .primary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(config.nameFormatter(person, config.nameFormat))
    }
}

// MARK: - Small, reusable modifier for hit testing

private struct HitModifier: ViewModifier {
    let behavior: PersonViewConfig.HitBehavior
    func body(content: Content) -> some View {
        switch behavior {
        case .none:
            content.allowsHitTesting(false)
        case .tap(let action):
            content.allowsHitTesting(true).onTapGesture(perform: action)
        case .custom:
            content.allowsHitTesting(true) // gesture attached by caller elsewhere
        }
    }
}
