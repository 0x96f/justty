//
//  Theme.swift
//  justty
//

import GhosttyTheme
import os
import SwiftUI

enum ThemeMode: String, CaseIterable, Identifiable {
    case light
    case dark

    var id: Self { self }

    var label: String { rawValue.capitalized }
}

enum Theme {
    private struct Selection {
        var mode: ThemeMode
        var light: GhosttyThemeDefinition
        var dark: GhosttyThemeDefinition
    }

    // nonisolated: SWIFT_DEFAULT_ACTOR_ISOLATION is MainActor; terminal()/isDark/
    // backgroundColor must stay readable off the main actor via the lock below.
    nonisolated static let defaultLightThemeName = "GitHub Light Default"
    nonisolated static let defaultDarkThemeName = "GitHub Dark Default"

    private nonisolated static let selection = OSAllocatedUnfairLock(
        initialState: Selection(
            mode: .dark,
            light: defaultLightDefinition,
            dark: defaultDarkDefinition
        )
    )

    nonisolated static var defaultLightDefinition: GhosttyThemeDefinition {
        definition(named: defaultLightThemeName)
            ?? GhosttyThemeDefinition(
                name: defaultLightThemeName,
                background: "ffffff",
                foreground: "24292f"
            )
    }

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

    nonisolated static func mode(named name: String?) -> ThemeMode? {
        guard let definition = name.flatMap({ definition(named: $0) }) else {
            return nil
        }
        return definition.isDark ? .dark : .light
    }

    nonisolated static func resolvedName(_ name: String?, for mode: ThemeMode) -> String {
        guard let name,
              let definition = definition(named: name),
              definition.isDark == (mode == .dark)
        else {
            return mode == .dark ? defaultDarkThemeName : defaultLightThemeName
        }
        return name
    }

    /// Re-resolves the selected themes by name. Unknown names fall back to section defaults.
    static func reloadSelection(
        themeMode: ThemeMode,
        lightThemeName: String,
        darkThemeName: String
    ) {
        let light = resolvedDefinition(named: lightThemeName, for: .light)
        let dark = resolvedDefinition(named: darkThemeName, for: .dark)
        selection.withLock {
            $0 = Selection(mode: themeMode, light: light, dark: dark)
        }
    }

    /// Backward-compatible single-theme reload used by older tests and callers.
    static func reloadSelection(_ name: String) {
        switch mode(named: name) {
        case .light:
            reloadSelection(
                themeMode: .light,
                lightThemeName: name,
                darkThemeName: defaultDarkThemeName
            )
        case .dark:
            reloadSelection(
                themeMode: .dark,
                lightThemeName: defaultLightThemeName,
                darkThemeName: name
            )
        case nil:
            reloadSelection(
                themeMode: .dark,
                lightThemeName: defaultLightThemeName,
                darkThemeName: defaultDarkThemeName
            )
        }
    }

    /// The selected ghostty theme for the active appearance.
    nonisolated static func terminal() -> GhosttyThemeDefinition {
        selection.withLock { $0.mode == .dark ? $0.dark : $0.light }
    }

    nonisolated static func lightTerminal() -> GhosttyThemeDefinition {
        selection.withLock { $0.light }
    }

    nonisolated static func darkTerminal() -> GhosttyThemeDefinition {
        selection.withLock { $0.dark }
    }

    /// Whether the selected appearance is dark (drives chrome + color scheme).
    nonisolated static var isDark: Bool {
        selection.withLock { $0.mode == .dark }
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

    private nonisolated static func resolvedDefinition(
        named name: String,
        for mode: ThemeMode
    ) -> GhosttyThemeDefinition {
        if let definition = definition(named: name),
           definition.isDark == (mode == .dark) {
            return definition
        }
        return mode == .dark ? defaultDarkDefinition : defaultLightDefinition
    }

    private nonisolated static func color(hex: String) -> Color? {
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
