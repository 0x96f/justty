//
//  AppSettingsTests.swift
//  justtyTests
//

import Foundation
import Testing
@testable import Justty

@MainActor
struct AppSettingsTests {
    private func makeSuite() throws -> (suiteName: String, defaults: UserDefaults) {
        let suiteName = "dev.justty.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return (suiteName, defaults)
    }

    @Test func missingIntKeysUseDefaults() throws {
        let (_, defaults) = try makeSuite()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.terminalPadding == AppSettings.Defaults.terminalPadding)
        #expect(settings.windowOriginX == AppSettings.Defaults.windowOriginX)
        #expect(settings.windowOriginY == AppSettings.Defaults.windowOriginY)
        #expect(settings.windowColumns == AppSettings.Defaults.windowColumns)
        #expect(settings.windowRows == AppSettings.Defaults.windowRows)
    }

    @Test func storedZeroPaddingAndOriginArePreserved() throws {
        let (suiteName, defaults) = try makeSuite()
        defaults.set(0, forKey: "terminalPadding")
        defaults.set(0, forKey: "windowOriginX")
        defaults.set(0, forKey: "windowOriginY")
        let settings = AppSettings(defaults: defaults)
        #expect(settings.terminalPadding == 0)
        #expect(settings.windowOriginX == 0)
        #expect(settings.windowOriginY == 0)
        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test func fontSizeClampsToLimits() throws {
        let (_, defaults) = try makeSuite()
        let settings = AppSettings(defaults: defaults)
        settings.fontSize = 1
        #expect(settings.fontSize == AppSettings.Limits.fontSize.lowerBound)
        settings.fontSize = 100
        #expect(settings.fontSize == AppSettings.Limits.fontSize.upperBound)
    }

    @Test func terminalPaddingClampsToLimits() throws {
        let (_, defaults) = try makeSuite()
        let settings = AppSettings(defaults: defaults)
        settings.terminalPadding = -5
        #expect(settings.terminalPadding == AppSettings.Limits.terminalPadding.lowerBound)
        settings.terminalPadding = 999
        #expect(settings.terminalPadding == AppSettings.Limits.terminalPadding.upperBound)
    }

    @Test func windowColumnsAndRowsClampToLimits() throws {
        let (_, defaults) = try makeSuite()
        let settings = AppSettings(defaults: defaults)
        settings.windowColumns = 1
        #expect(settings.windowColumns == AppSettings.Limits.windowColumns.lowerBound)
        settings.windowColumns = 10_000
        #expect(settings.windowColumns == AppSettings.Limits.windowColumns.upperBound)
        settings.windowRows = 1
        #expect(settings.windowRows == AppSettings.Limits.windowRows.lowerBound)
        settings.windowRows = 10_000
        #expect(settings.windowRows == AppSettings.Limits.windowRows.upperBound)
    }

    @Test func windowOriginClampsToLimits() throws {
        let (_, defaults) = try makeSuite()
        let settings = AppSettings(defaults: defaults)
        settings.windowOriginX = -10
        #expect(settings.windowOriginX == AppSettings.Limits.windowOrigin.lowerBound)
        settings.windowOriginY = 50_000
        #expect(settings.windowOriginY == AppSettings.Limits.windowOrigin.upperBound)
    }

    @Test func zeroFontSizeUsesDefaultSize() throws {
        let (_, defaults) = try makeSuite()
        defaults.set(0.0, forKey: "fontSize")
        let settings = AppSettings(defaults: defaults)
        #expect(settings.fontSize == Double(TerminalFont.defaultSize))
    }
}
