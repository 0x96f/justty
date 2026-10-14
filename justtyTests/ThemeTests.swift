//
//  ThemeTests.swift
//  justtyTests
//

import GhosttyTheme
import Testing
@testable import Justty

struct ThemeTests {
    @Test func unknownNameReloadsToDarkDefault() {
        Theme.reloadSelection("definitely-not-a-real-theme-name")
        #expect(Theme.terminal().name == Theme.defaultDarkThemeName)
    }

    @Test func darkThemeNamesLeadWithDefaultAndAreUnique() {
        let names = Theme.darkThemeNames
        #expect(names.first == Theme.defaultDarkThemeName)
        #expect(Set(names).count == names.count)
        #expect(!names.isEmpty)
    }

    @Test func lightThemeNamesLeadWithDefaultAndAreUnique() {
        let names = Theme.lightThemeNames
        #expect(names.first == Theme.defaultLightThemeName)
        #expect(Set(names).count == names.count)
        #expect(!names.isEmpty)
    }

    @Test func knownThemeReloadKeepsName() {
        Theme.reloadSelection(Theme.defaultLightThemeName)
        #expect(Theme.terminal().name == Theme.defaultLightThemeName)
        Theme.reloadSelection(Theme.defaultDarkThemeName)
        #expect(Theme.terminal().name == Theme.defaultDarkThemeName)
    }

    @Test func separateLightAndDarkSelectionsKeepBothThemes() {
        Theme.reloadSelection(
            themeMode: .light,
            lightThemeName: Theme.defaultLightThemeName,
            darkThemeName: Theme.defaultDarkThemeName
        )
        #expect(Theme.terminal().name == Theme.defaultLightThemeName)
        #expect(Theme.lightTerminal().name == Theme.defaultLightThemeName)
        #expect(Theme.darkTerminal().name == Theme.defaultDarkThemeName)
        #expect(Theme.isDark == false)

        Theme.reloadSelection(
            themeMode: .dark,
            lightThemeName: Theme.defaultLightThemeName,
            darkThemeName: Theme.defaultDarkThemeName
        )
        #expect(Theme.terminal().name == Theme.defaultDarkThemeName)
        #expect(Theme.isDark == true)
    }
}
