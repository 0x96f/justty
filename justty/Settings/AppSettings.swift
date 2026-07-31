//
//  AppSettings.swift
//  justty
//

import AppKit
import Combine
import Foundation
import OSLog

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private static let logger = Logger(subsystem: "dev.justty", category: "settings")
    private static let defaultPersistDebounce: Duration = .milliseconds(250)

    private let configURL: URL
    private let persistDebounce: Duration
    private var persistTask: Task<Void, Never>?

    enum Defaults {
        static let lineHeight = 1.0
        static let terminalPadding = 0
        static let windowOriginX = 0
        static let windowOriginY = 0
        static let windowColumns = 80
        static let windowRows = 24
        static let confirmCloseRunningCommand = true
        static let showCwdInTabTitle = true
    }

    enum Limits {
        static let fontSize = 8.0...32.0
        static let lineHeight = 0.8...2.0
        static let terminalPadding = 0...64
        static let windowOrigin = 0...10_000
        static let windowColumns = 20...500
        static let windowRows = 5...200
    }

    @Published var theme: String {
        didSet {
            guard !isLoading else { return }
            Theme.reloadSelection(theme)
            applyAppAppearance()
            persistAndNotify()
        }
    }

    @Published var fontFamily: String {
        didSet {
            guard !isLoading else { return }
            persistAndNotify()
        }
    }

    @Published var fontSize: Double {
        didSet {
            guard !isLoading else { return }
            let clamped = Self.clamp(fontSize, to: Limits.fontSize)
            if clamped != fontSize {
                fontSize = clamped
                return
            }
            persistAndNotify()
        }
    }

    @Published var fontWeight: FontWeightSetting {
        didSet {
            guard !isLoading else { return }
            persistAndNotify()
        }
    }

    @Published var lineHeight: Double {
        didSet {
            guard !isLoading else { return }
            let clamped = Self.clamp(lineHeight, to: Limits.lineHeight)
            if clamped != lineHeight {
                lineHeight = clamped
                return
            }
            persistAndNotify()
        }
    }

    @Published var terminalPadding: Int {
        didSet {
            guard !isLoading else { return }
            let clamped = Self.clamp(terminalPadding, to: Limits.terminalPadding)
            if clamped != terminalPadding {
                terminalPadding = clamped
                return
            }
            persistAndNotify()
        }
    }

    @Published var windowOriginX: Int {
        didSet {
            guard !isLoading else { return }
            let clamped = Self.clamp(windowOriginX, to: Limits.windowOrigin)
            if clamped != windowOriginX {
                windowOriginX = clamped
                return
            }
            persistAndNotify()
        }
    }

    @Published var windowOriginY: Int {
        didSet {
            guard !isLoading else { return }
            let clamped = Self.clamp(windowOriginY, to: Limits.windowOrigin)
            if clamped != windowOriginY {
                windowOriginY = clamped
                return
            }
            persistAndNotify()
        }
    }

    @Published var windowColumns: Int {
        didSet {
            guard !isLoading else { return }
            let clamped = Self.clamp(windowColumns, to: Limits.windowColumns)
            if clamped != windowColumns {
                windowColumns = clamped
                return
            }
            persistAndNotify()
        }
    }

    @Published var windowRows: Int {
        didSet {
            guard !isLoading else { return }
            let clamped = Self.clamp(windowRows, to: Limits.windowRows)
            if clamped != windowRows {
                windowRows = clamped
                return
            }
            persistAndNotify()
        }
    }

    @Published var confirmCloseRunningCommand: Bool {
        didSet {
            guard !isLoading else { return }
            persistAndNotify()
        }
    }

    @Published var showCwdInTabTitle: Bool {
        didSet {
            guard !isLoading else { return }
            persistAndNotify()
        }
    }

    /// True while seeding properties from disk so didSet side effects
    /// (including `NSApp`, which is still nil during `App.init`) do not run.
    private var isLoading = true

    convenience init() {
        self.init(configURL: JusttyConfigStore.defaultURL)
    }

    init(
        configURL: URL,
        persistDebounce: Duration = AppSettings.defaultPersistDebounce
    ) {
        self.configURL = configURL
        self.persistDebounce = persistDebounce

        // Placeholders so `apply` can run from init; immediately overwritten.
        theme = Theme.defaultDarkThemeName
        fontFamily = ""
        fontSize = Double(TerminalFont.defaultSize)
        fontWeight = .regular
        lineHeight = Defaults.lineHeight
        terminalPadding = Defaults.terminalPadding
        windowOriginX = Defaults.windowOriginX
        windowOriginY = Defaults.windowOriginY
        windowColumns = Defaults.windowColumns
        windowRows = Defaults.windowRows
        confirmCloseRunningCommand = Defaults.confirmCloseRunningCommand
        showCwdInTabTitle = Defaults.showCwdInTabTitle

        apply(Self.loadOrCreate(at: configURL))
        Theme.reloadSelection(theme)
        isLoading = false
        observeAppTermination()
    }

    /// Re-read `config.yml` and apply (File → Reload Configuration).
    func reloadFromDisk() {
        let config: JusttyConfigFile
        do {
            config = try JusttyConfigStore.load(from: configURL)
        } catch {
            Self.logger.error("Failed to reload configuration: \(error.localizedDescription, privacy: .public)")
            presentReloadFailure(error)
            return
        }

        isLoading = true
        apply(config)
        isLoading = false

        Theme.reloadSelection(theme)
        applyAppAppearance()
        NotificationCenter.default.post(name: .justtySettingsDidChange, object: nil)
    }

    /// Ensure the config file exists, then open it in a text editor (Ghostty-style).
    func openConfigFile() {
        do {
            _ = try JusttyConfigStore.ensureExists(at: configURL, seeding: makeConfigFile())
        } catch {
            Self.logger.error("Failed to ensure config file: \(error.localizedDescription, privacy: .public)")
            // Still try to open; editor may create or show an error.
        }
        JusttyConfigStore.openInEditor(url: configURL)
    }

    /// Apply chrome light/dark from the selected theme once AppKit exists.
    func applyAppAppearance() {
        NSApp?.appearance = NSAppearance(
            named: Theme.isDark ? .darkAqua : .aqua
        )
    }

    /// Cancel a pending debounced write and persist immediately (tests / quit).
    func flushPendingPersist() {
        persistTask?.cancel()
        persistTask = nil
        writeConfigToDisk()
    }

    private func apply(_ config: JusttyConfigFile) {
        theme = Self.resolvedTheme(config.theme)
        fontFamily = config.font.family
        fontSize = Self.resolvedFontSize(Double(config.font.size))
        fontWeight = FontWeightSetting(rawValue: config.font.weight) ?? .regular
        lineHeight = Self.clamp(config.font.lineHeight, to: Limits.lineHeight)
        terminalPadding = Self.clamp(config.window.padding, to: Limits.terminalPadding)
        windowOriginX = Self.clamp(config.window.originX, to: Limits.windowOrigin)
        windowOriginY = Self.clamp(config.window.originY, to: Limits.windowOrigin)
        windowColumns = Self.clamp(config.window.columns, to: Limits.windowColumns)
        windowRows = Self.clamp(config.window.rows, to: Limits.windowRows)
        confirmCloseRunningCommand = config.confirmCloseRunningCommand
        showCwdInTabTitle = config.showCwdInTabTitle
    }

    private func persistAndNotify() {
        NotificationCenter.default.post(name: .justtySettingsDidChange, object: nil)
        schedulePersist()
    }

    private func schedulePersist() {
        persistTask?.cancel()
        if persistDebounce == .zero {
            writeConfigToDisk()
            return
        }
        let delay = persistDebounce
        persistTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: delay)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            self?.writeConfigToDisk()
        }
    }

    private func writeConfigToDisk() {
        do {
            try JusttyConfigStore.save(makeConfigFile(), to: configURL)
        } catch {
            Self.logger.error("Failed to save configuration: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func observeAppTermination() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.flushPendingPersist()
            }
        }
    }

    private func presentReloadFailure(_ error: Error) {
        // Sheet only — never `runModal`, so XCTest / no-window cases just log.
        guard let window = NSApp?.keyWindow ?? NSApp?.mainWindow else { return }

        let alert = NSAlert()
        alert.messageText = "Couldn’t Reload Configuration"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: window)
    }

    private func makeConfigFile() -> JusttyConfigFile {
        JusttyConfigFile(
            theme: theme,
            font: .init(
                family: fontFamily,
                size: Int(fontSize.rounded()),
                weight: fontWeight.rawValue,
                lineHeight: lineHeight
            ),
            window: .init(
                padding: terminalPadding,
                originX: windowOriginX,
                originY: windowOriginY,
                columns: windowColumns,
                rows: windowRows
            ),
            confirmCloseRunningCommand: confirmCloseRunningCommand,
            showCwdInTabTitle: showCwdInTabTitle
        )
    }

    private static func loadOrCreate(at url: URL) -> JusttyConfigFile {
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                return try JusttyConfigStore.load(from: url)
            } catch {
                logger.error("Failed to load configuration; using defaults: \(error.localizedDescription, privacy: .public)")
                return .default
            }
        }

        // One-shot migrate from UserDefaults only for the real config path
        // so tests with temp files get pure defaults.
        let seeding: JusttyConfigFile
        if url.standardizedFileURL == JusttyConfigStore.defaultURL.standardizedFileURL {
            seeding = migrateFromUserDefaults() ?? .default
        } else {
            seeding = .default
        }
        do {
            try JusttyConfigStore.save(seeding, to: url)
        } catch {
            logger.error("Failed to create configuration file: \(error.localizedDescription, privacy: .public)")
        }
        return seeding
    }

    /// Seeds a first YAML file from legacy UserDefaults keys when present.
    private static func migrateFromUserDefaults() -> JusttyConfigFile? {
        let defaults = UserDefaults.standard
        let legacyKeys = [
            "theme", "fontFamily", "fontSize", "fontWeight", "lineHeight",
            "terminalPadding", "windowOriginX", "windowOriginY",
            "windowColumns", "windowRows",
        ]
        let hasAny = legacyKeys.contains { defaults.object(forKey: $0) != nil }
        guard hasAny else { return nil }

        var config = JusttyConfigFile.default
        if let theme = defaults.string(forKey: "theme") {
            config.theme = resolvedTheme(theme)
        }
        if let family = defaults.string(forKey: "fontFamily") {
            config.font.family = family
        }
        let storedSize = defaults.double(forKey: "fontSize")
        if defaults.object(forKey: "fontSize") != nil {
            config.font.size = Int(resolvedFontSize(storedSize).rounded())
        }
        if let weight = defaults.string(forKey: "fontWeight") {
            config.font.weight = FontWeightSetting(rawValue: weight)?.rawValue
                ?? FontWeightSetting.regular.rawValue
        }
        if defaults.object(forKey: "lineHeight") != nil {
            config.font.lineHeight = clamp(
                defaults.double(forKey: "lineHeight"),
                to: Limits.lineHeight
            )
        }
        if defaults.object(forKey: "terminalPadding") != nil {
            config.window.padding = clamp(
                defaults.integer(forKey: "terminalPadding"),
                to: Limits.terminalPadding
            )
        }
        if defaults.object(forKey: "windowOriginX") != nil {
            config.window.originX = clamp(
                defaults.integer(forKey: "windowOriginX"),
                to: Limits.windowOrigin
            )
        }
        if defaults.object(forKey: "windowOriginY") != nil {
            config.window.originY = clamp(
                defaults.integer(forKey: "windowOriginY"),
                to: Limits.windowOrigin
            )
        }
        if defaults.object(forKey: "windowColumns") != nil {
            config.window.columns = clamp(
                defaults.integer(forKey: "windowColumns"),
                to: Limits.windowColumns
            )
        }
        if defaults.object(forKey: "windowRows") != nil {
            config.window.rows = clamp(
                defaults.integer(forKey: "windowRows"),
                to: Limits.windowRows
            )
        }
        return config
    }

    private static func resolvedTheme(_ name: String) -> String {
        knownTheme(name) ?? Theme.defaultDarkThemeName
    }

    private static func resolvedFontSize(_ size: Double) -> Double {
        size == 0 ? TerminalFont.defaultSize : clamp(size, to: Limits.fontSize)
    }

    private static func knownTheme(_ name: String?) -> String? {
        guard let name, Theme.definition(named: name) != nil else {
            return nil
        }
        return name
    }

    private static func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }

    private static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

extension Notification.Name {
    /// Posted when any setting that affects live terminals or window chrome changes.
    static let justtySettingsDidChange = Notification.Name("justtySettingsDidChange")
}
