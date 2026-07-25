//
//  AppSettings.swift
//  justty
//

import AppKit
import Combine
import Foundation

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults: UserDefaults

    private enum Key {
        static let theme = "theme"
        static let fontFamily = "fontFamily"
        static let fontSize = "fontSize"
        static let fontWeight = "fontWeight"
        static let lineHeight = "lineHeight"
        static let terminalPadding = "terminalPadding"
        static let windowOriginX = "windowOriginX"
        static let windowOriginY = "windowOriginY"
        static let windowColumns = "windowColumns"
        static let windowRows = "windowRows"
    }

    enum Defaults {
        static let lineHeight = 1.0
        static let terminalPadding = 0
        static let windowOriginX = 0
        static let windowOriginY = 0
        static let windowColumns = 80
        static let windowRows = 24
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
            defaults.set(theme, forKey: Key.theme)
            Theme.reloadSelection(theme)
            applyAppAppearance()
            NotificationCenter.default.post(name: .justtySettingsDidChange, object: nil)
        }
    }

    @Published var fontFamily: String {
        didSet {
            guard !isLoading else { return }
            defaults.set(fontFamily, forKey: Key.fontFamily)
            NotificationCenter.default.post(name: .justtySettingsDidChange, object: nil)
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
            defaults.set(fontSize, forKey: Key.fontSize)
            NotificationCenter.default.post(name: .justtySettingsDidChange, object: nil)
        }
    }

    @Published var fontWeight: FontWeightSetting {
        didSet {
            guard !isLoading else { return }
            defaults.set(fontWeight.rawValue, forKey: Key.fontWeight)
            NotificationCenter.default.post(name: .justtySettingsDidChange, object: nil)
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
            defaults.set(lineHeight, forKey: Key.lineHeight)
            NotificationCenter.default.post(name: .justtySettingsDidChange, object: nil)
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
            defaults.set(terminalPadding, forKey: Key.terminalPadding)
            NotificationCenter.default.post(name: .justtySettingsDidChange, object: nil)
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
            defaults.set(windowOriginX, forKey: Key.windowOriginX)
            NotificationCenter.default.post(name: .justtySettingsDidChange, object: nil)
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
            defaults.set(windowOriginY, forKey: Key.windowOriginY)
            NotificationCenter.default.post(name: .justtySettingsDidChange, object: nil)
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
            defaults.set(windowColumns, forKey: Key.windowColumns)
            NotificationCenter.default.post(name: .justtySettingsDidChange, object: nil)
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
            defaults.set(windowRows, forKey: Key.windowRows)
            NotificationCenter.default.post(name: .justtySettingsDidChange, object: nil)
        }
    }

    /// True while seeding properties from UserDefaults so didSet side effects
    /// (including `NSApp`, which is still nil during `App.init`) do not run.
    private var isLoading = true

    convenience init() {
        self.init(defaults: .standard)
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults

        theme = Self.knownTheme(defaults.string(forKey: Key.theme))
            ?? Theme.defaultDarkThemeName
        fontFamily = defaults.string(forKey: Key.fontFamily) ?? ""
        let storedSize = defaults.double(forKey: Key.fontSize)
        fontSize = storedSize == 0
            ? TerminalFont.defaultSize
            : Self.clamp(storedSize, to: Limits.fontSize)
        let weightRaw = defaults.string(forKey: Key.fontWeight) ?? FontWeightSetting.regular.rawValue
        fontWeight = FontWeightSetting(rawValue: weightRaw) ?? .regular
        lineHeight = Self.double(
            defaults,
            key: Key.lineHeight,
            default: Defaults.lineHeight,
            limits: Limits.lineHeight
        )

        terminalPadding = Self.int(
            defaults,
            key: Key.terminalPadding,
            default: Defaults.terminalPadding,
            limits: Limits.terminalPadding
        )
        windowOriginX = Self.int(
            defaults,
            key: Key.windowOriginX,
            default: Defaults.windowOriginX,
            limits: Limits.windowOrigin
        )
        windowOriginY = Self.int(
            defaults,
            key: Key.windowOriginY,
            default: Defaults.windowOriginY,
            limits: Limits.windowOrigin
        )
        windowColumns = Self.int(
            defaults,
            key: Key.windowColumns,
            default: Defaults.windowColumns,
            limits: Limits.windowColumns
        )
        windowRows = Self.int(
            defaults,
            key: Key.windowRows,
            default: Defaults.windowRows,
            limits: Limits.windowRows
        )

        Theme.reloadSelection(theme)
        isLoading = false
    }

    /// Apply chrome light/dark from the selected theme once AppKit exists.
    func applyAppAppearance() {
        NSApp?.appearance = NSAppearance(
            named: Theme.isDark ? .darkAqua : .aqua
        )
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

    /// Reads an Int from UserDefaults. Missing keys use `default`; `0` is a
    /// valid stored value (unlike font size, which uses 0 as “unset”).
    private static func int(
        _ defaults: UserDefaults,
        key: String,
        default defaultValue: Int,
        limits: ClosedRange<Int>
    ) -> Int {
        guard defaults.object(forKey: key) != nil else {
            return defaultValue
        }
        return clamp(defaults.integer(forKey: key), to: limits)
    }

    private static func double(
        _ defaults: UserDefaults,
        key: String,
        default defaultValue: Double,
        limits: ClosedRange<Double>
    ) -> Double {
        guard defaults.object(forKey: key) != nil else {
            return defaultValue
        }
        return clamp(defaults.double(forKey: key), to: limits)
    }
}

extension Notification.Name {
    /// Posted when any setting that affects live terminals or window chrome changes.
    static let justtySettingsDidChange = Notification.Name("justtySettingsDidChange")
}
