//
//  Theme.swift
//  justty
//

import GhosttyTheme
import os
import SwiftUI

enum Theme {
    static let defaultLightThemeName = "GitHub Light Default"
    static let defaultDarkThemeName = "GitHub Dark Default"

    private static let selection = OSAllocatedUnfairLock(
        initialState: defaultDarkDefinition
    )

    nonisolated static var defaultDarkDefinition: GhosttyThemeDefinition {
        definition(named: defaultDarkThemeName)
            ?? GhosttyThemeDefinition(
                name: defaultDarkThemeName,
                background: "0d1117",
                foreground: "e6edf3"
            )
    }

    nonisolated static func definition(named name: String) -> GhosttyThemeDefinition? {
        GhosttyThemeCatalog.theme(named: name)
    }

    /// Re-resolves the selected theme by name. Unknown names keep the dark default.
    @MainActor
    static func reloadSelection(_ name: String) {
        let resolved = definition(named: name) ?? defaultDarkDefinition
        selection.withLock { $0 = resolved }
    }

    /// The selected ghostty theme.
    nonisolated static func terminal() -> GhosttyThemeDefinition {
        selection.withLock { $0 }
    }

    /// Whether the selected theme is dark (drives chrome + color scheme).
    nonisolated static var isDark: Bool {
        selection.withLock { $0.isDark }
    }

    /// Terminal background as a SwiftUI color (for chrome that should match the grid).
    nonisolated static var backgroundColor: Color {
        color(hex: terminal().background) ?? Color(white: isDark ? 0.05 : 1)
    }

    /// Dark-section picker names: default first, then every dark catalog theme.
    static var darkThemeNames: [String] {
        uniqueNames(
            leading: defaultDarkThemeName,
            rest: GhosttyThemeCatalog.allThemes.filter(\.isDark).map(\.name)
        )
    }

    /// Light-section picker names: default first, then every light catalog theme.
    static var lightThemeNames: [String] {
        uniqueNames(
            leading: defaultLightThemeName,
            rest: GhosttyThemeCatalog.allThemes.filter { !$0.isDark }.map(\.name)
        )
    }

    private static func uniqueNames(leading: String, rest: [String]) -> [String] {
        var seen = Set<String>()
        var names: [String] = []
        for name in [leading] + rest {
            if seen.insert(name).inserted {
                names.append(name)
            }
        }
        return names
    }

    private static func color(hex: String) -> Color? {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") {
            value.removeFirst()
        }
        guard value.count >= 6,
              let r = UInt8(value.prefix(2), radix: 16),
              let g = UInt8(value.dropFirst(2).prefix(2), radix: 16),
              let b = UInt8(value.dropFirst(4).prefix(2), radix: 16)
        else { return nil }
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
