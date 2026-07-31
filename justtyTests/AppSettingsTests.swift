//
//  AppSettingsTests.swift
//  justtyTests
//

import Foundation
import Testing
@testable import Justty

@MainActor
struct AppSettingsTests {
    private func makeTempConfigURL() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("justty-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("config.yml")
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    /// Immediate disk writes so assertions can read the file without waiting.
    private func makeSettings(configURL: URL) -> AppSettings {
        AppSettings(configURL: configURL, persistDebounce: .zero)
    }

    @Test func missingFileCreatesDefaults() throws {
        let url = try makeTempConfigURL()
        defer { cleanup(url) }

        let settings = makeSettings(configURL: url)
        #expect(settings.terminalPadding == AppSettings.Defaults.terminalPadding)
        #expect(settings.windowOriginX == AppSettings.Defaults.windowOriginX)
        #expect(settings.windowOriginY == AppSettings.Defaults.windowOriginY)
        #expect(settings.windowColumns == AppSettings.Defaults.windowColumns)
        #expect(settings.windowRows == AppSettings.Defaults.windowRows)
        #expect(settings.confirmCloseRunningCommand == AppSettings.Defaults.confirmCloseRunningCommand)
        #expect(settings.showCwdInTabTitle == AppSettings.Defaults.showCwdInTabTitle)
        #expect(settings.fontSize == Double(TerminalFont.defaultSize))
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    @Test func storedZeroPaddingAndOriginArePreserved() throws {
        let url = try makeTempConfigURL()
        defer { cleanup(url) }

        var config = JusttyConfigFile.default
        config.window.padding = 0
        config.window.originX = 0
        config.window.originY = 0
        try JusttyConfigStore.save(config, to: url)

        let settings = makeSettings(configURL: url)
        #expect(settings.terminalPadding == 0)
        #expect(settings.windowOriginX == 0)
        #expect(settings.windowOriginY == 0)
    }

    @Test func fontSizeClampsToLimits() throws {
        let url = try makeTempConfigURL()
        defer { cleanup(url) }

        let settings = makeSettings(configURL: url)
        settings.fontSize = 1
        #expect(settings.fontSize == AppSettings.Limits.fontSize.lowerBound)
        settings.fontSize = 100
        #expect(settings.fontSize == AppSettings.Limits.fontSize.upperBound)
    }

    @Test func terminalPaddingClampsToLimits() throws {
        let url = try makeTempConfigURL()
        defer { cleanup(url) }

        let settings = makeSettings(configURL: url)
        settings.terminalPadding = -5
        #expect(settings.terminalPadding == AppSettings.Limits.terminalPadding.lowerBound)
        settings.terminalPadding = 999
        #expect(settings.terminalPadding == AppSettings.Limits.terminalPadding.upperBound)
    }

    @Test func windowColumnsAndRowsClampToLimits() throws {
        let url = try makeTempConfigURL()
        defer { cleanup(url) }

        let settings = makeSettings(configURL: url)
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
        let url = try makeTempConfigURL()
        defer { cleanup(url) }

        let settings = makeSettings(configURL: url)
        settings.windowOriginX = -10
        #expect(settings.windowOriginX == AppSettings.Limits.windowOrigin.lowerBound)
        settings.windowOriginY = 50_000
        #expect(settings.windowOriginY == AppSettings.Limits.windowOrigin.upperBound)
    }

    @Test func zeroFontSizeUsesDefaultSize() throws {
        let url = try makeTempConfigURL()
        defer { cleanup(url) }

        var config = JusttyConfigFile.default
        config.font.size = 0
        try JusttyConfigStore.save(config, to: url)

        let settings = makeSettings(configURL: url)
        #expect(settings.fontSize == Double(TerminalFont.defaultSize))
    }

    @Test func fontSizeAndLineHeightYAMLFormatting() throws {
        let url = try makeTempConfigURL()
        defer { cleanup(url) }

        let settings = makeSettings(configURL: url)
        settings.fontSize = 14
        settings.lineHeight = 1.4

        let yaml = try String(contentsOf: url, encoding: .utf8)
        #expect(yaml.contains("size: 14"))
        #expect(!yaml.contains("1.4e+"))
        #expect(yaml.contains("line_height: 1.40"))

        let loaded = try JusttyConfigStore.load(from: url)
        #expect(loaded.font.size == 14)
        #expect(loaded.font.lineHeight == 1.4)
    }

    @Test func uiChangePersistsToFile() throws {
        let url = try makeTempConfigURL()
        defer { cleanup(url) }

        let settings = makeSettings(configURL: url)
        settings.terminalPadding = 12
        settings.windowColumns = 100

        let loaded = try JusttyConfigStore.load(from: url)
        #expect(loaded.window.padding == 12)
        #expect(loaded.window.columns == 100)
    }

    @Test func debouncedPersistWritesAfterDelay() async throws {
        let url = try makeTempConfigURL()
        defer { cleanup(url) }

        let settings = AppSettings(
            configURL: url,
            persistDebounce: .milliseconds(50)
        )
        let initial = try String(contentsOf: url, encoding: .utf8)

        settings.terminalPadding = 12
        // Still the seed file immediately after change.
        let mid = try String(contentsOf: url, encoding: .utf8)
        #expect(mid == initial)

        try await Task.sleep(for: .milliseconds(120))
        let loaded = try JusttyConfigStore.load(from: url)
        #expect(loaded.window.padding == 12)
    }

    @Test func flushPendingPersistWritesImmediately() throws {
        let url = try makeTempConfigURL()
        defer { cleanup(url) }

        let settings = AppSettings(
            configURL: url,
            persistDebounce: .milliseconds(5_000)
        )
        settings.terminalPadding = 18
        settings.flushPendingPersist()

        let loaded = try JusttyConfigStore.load(from: url)
        #expect(loaded.window.padding == 18)
    }

    @Test func reloadFromDiskAppliesFileChanges() throws {
        let url = try makeTempConfigURL()
        defer { cleanup(url) }

        let settings = makeSettings(configURL: url)
        #expect(settings.terminalPadding == AppSettings.Defaults.terminalPadding)

        var config = JusttyConfigFile.default
        config.window.padding = 24
        config.window.rows = 40
        try JusttyConfigStore.save(config, to: url)

        settings.reloadFromDisk()
        #expect(settings.terminalPadding == 24)
        #expect(settings.windowRows == 40)
    }

    @Test func reloadFromDiskKeepsValuesOnCorruptFile() throws {
        let url = try makeTempConfigURL()
        defer { cleanup(url) }

        let settings = makeSettings(configURL: url)
        settings.terminalPadding = 12
        settings.windowColumns = 100

        try "not: valid: yaml: [[["
            .write(to: url, atomically: true, encoding: .utf8)

        settings.reloadFromDisk()
        #expect(settings.terminalPadding == 12)
        #expect(settings.windowColumns == 100)
    }

    @Test func missingKeysUseDefaultsOnLoadAndReload() throws {
        let url = try makeTempConfigURL()
        defer { cleanup(url) }

        // Partial file: only theme + one window field; everything else defaults.
        try """
        theme: GitHub Dark Default
        window:
          padding: 16
        """.write(to: url, atomically: true, encoding: .utf8)

        let settings = makeSettings(configURL: url)
        #expect(settings.theme == "GitHub Dark Default")
        #expect(settings.terminalPadding == 16)
        #expect(settings.fontSize == Double(TerminalFont.defaultSize))
        #expect(settings.lineHeight == AppSettings.Defaults.lineHeight)
        #expect(settings.windowColumns == AppSettings.Defaults.windowColumns)
        #expect(settings.windowRows == AppSettings.Defaults.windowRows)

        try """
        font:
          size: 18
        """.write(to: url, atomically: true, encoding: .utf8)

        settings.reloadFromDisk()
        #expect(settings.fontSize == 18)
        #expect(settings.theme == Theme.defaultDarkThemeName)
        #expect(settings.terminalPadding == AppSettings.Defaults.terminalPadding)
        #expect(settings.windowColumns == AppSettings.Defaults.windowColumns)
    }

    @Test func confirmCloseRunningCommandDefaultsTrue() throws {
        let url = try makeTempConfigURL()
        defer { cleanup(url) }

        let settings = makeSettings(configURL: url)
        #expect(settings.confirmCloseRunningCommand == true)
        #expect(AppSettings.Defaults.confirmCloseRunningCommand == true)
    }

    @Test func missingConfirmCloseKeyDefaultsToTrue() throws {
        let url = try makeTempConfigURL()
        defer { cleanup(url) }

        try """
        theme: GitHub Dark Default
        window:
          padding: 8
        """.write(to: url, atomically: true, encoding: .utf8)

        let settings = makeSettings(configURL: url)
        #expect(settings.confirmCloseRunningCommand == true)
    }

    @Test func confirmCloseRunningCommandPersistsAndReloads() throws {
        let url = try makeTempConfigURL()
        defer { cleanup(url) }

        let settings = makeSettings(configURL: url)
        settings.confirmCloseRunningCommand = false

        let yaml = try String(contentsOf: url, encoding: .utf8)
        #expect(yaml.contains("confirm_close_running_command: false"))

        let loaded = try JusttyConfigStore.load(from: url)
        #expect(loaded.confirmCloseRunningCommand == false)

        var config = JusttyConfigFile.default
        config.confirmCloseRunningCommand = true
        try JusttyConfigStore.save(config, to: url)

        settings.reloadFromDisk()
        #expect(settings.confirmCloseRunningCommand == true)
    }

    @Test func showCwdInTabTitleDefaultsTrue() throws {
        let url = try makeTempConfigURL()
        defer { cleanup(url) }

        let settings = makeSettings(configURL: url)
        #expect(settings.showCwdInTabTitle == true)
        #expect(AppSettings.Defaults.showCwdInTabTitle == true)
    }

    @Test func missingShowCwdInTabTitleKeyDefaultsToTrue() throws {
        let url = try makeTempConfigURL()
        defer { cleanup(url) }

        try """
        theme: GitHub Dark Default
        window:
          padding: 8
        """.write(to: url, atomically: true, encoding: .utf8)

        let settings = makeSettings(configURL: url)
        #expect(settings.showCwdInTabTitle == true)
    }

    @Test func showCwdInTabTitlePersistsAndReloads() throws {
        let url = try makeTempConfigURL()
        defer { cleanup(url) }

        let settings = makeSettings(configURL: url)
        settings.showCwdInTabTitle = true

        let yaml = try String(contentsOf: url, encoding: .utf8)
        #expect(yaml.contains("show_cwd_in_tab_title: true"))

        let loaded = try JusttyConfigStore.load(from: url)
        #expect(loaded.showCwdInTabTitle == true)

        var config = JusttyConfigFile.default
        config.showCwdInTabTitle = false
        try JusttyConfigStore.save(config, to: url)

        settings.reloadFromDisk()
        #expect(settings.showCwdInTabTitle == false)
    }
}
