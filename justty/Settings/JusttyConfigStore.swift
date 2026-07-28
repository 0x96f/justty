//
//  JusttyConfigStore.swift
//  justty
//

import AppKit
import Foundation
import UniformTypeIdentifiers
import Yams

/// YAML float written as exactly two fractional digits (e.g. `1.40`), not scientific notation.
private struct TwoDecimalFloat: Equatable {
    var value: Double

    init(_ value: Double) {
        self.value = (value * 100).rounded() / 100
    }
}

extension TwoDecimalFloat: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(Double.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

extension TwoDecimalFloat: YAMLEncodable {
    func box() -> Node {
        Node(String(format: "%.2f", value), Tag(.float))
    }
}

/// On-disk YAML shape for `~/.config/justty/config.yml`.
/// Missing keys (including whole `font` / `window` sections) decode as defaults.
struct JusttyConfigFile: Codable, Equatable {
    struct Font: Codable, Equatable {
        var family: String
        /// Whole pixels in YAML (`14`, not `1.4e+1`).
        var size: Int
        var weight: String
        var lineHeight: Double

        enum CodingKeys: String, CodingKey {
            case family
            case size
            case weight
            case lineHeight = "line_height"
        }

        static var `default`: Font {
            Font(
                family: "",
                size: Int(TerminalFont.defaultSize.rounded()),
                weight: FontWeightSetting.regular.rawValue,
                lineHeight: AppSettings.Defaults.lineHeight
            )
        }

        init(family: String, size: Int, weight: String, lineHeight: Double) {
            self.family = family
            self.size = size
            self.weight = weight
            self.lineHeight = lineHeight
        }

        init(from decoder: Decoder) throws {
            let defaults = Font.default
            let container = try decoder.container(keyedBy: CodingKeys.self)
            family = try container.decodeIfPresent(String.self, forKey: .family) ?? defaults.family
            if container.contains(.size) {
                // Accept legacy scientific/float sizes from earlier YAML writes.
                if let intSize = try? container.decode(Int.self, forKey: .size) {
                    size = intSize
                } else if let doubleSize = try? container.decode(Double.self, forKey: .size) {
                    size = Int(doubleSize.rounded())
                } else {
                    size = defaults.size
                }
            } else {
                size = defaults.size
            }
            weight = try container.decodeIfPresent(String.self, forKey: .weight) ?? defaults.weight
            lineHeight = try container.decodeIfPresent(TwoDecimalFloat.self, forKey: .lineHeight)?.value
                ?? defaults.lineHeight
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(family, forKey: .family)
            try container.encode(size, forKey: .size)
            try container.encode(weight, forKey: .weight)
            try container.encode(TwoDecimalFloat(lineHeight), forKey: .lineHeight)
        }
    }

    struct Window: Codable, Equatable {
        var padding: Int
        var originX: Int
        var originY: Int
        var columns: Int
        var rows: Int

        enum CodingKeys: String, CodingKey {
            case padding
            case originX = "origin_x"
            case originY = "origin_y"
            case columns
            case rows
        }

        static var `default`: Window {
            Window(
                padding: AppSettings.Defaults.terminalPadding,
                originX: AppSettings.Defaults.windowOriginX,
                originY: AppSettings.Defaults.windowOriginY,
                columns: AppSettings.Defaults.windowColumns,
                rows: AppSettings.Defaults.windowRows
            )
        }

        init(padding: Int, originX: Int, originY: Int, columns: Int, rows: Int) {
            self.padding = padding
            self.originX = originX
            self.originY = originY
            self.columns = columns
            self.rows = rows
        }

        init(from decoder: Decoder) throws {
            let defaults = Window.default
            let container = try decoder.container(keyedBy: CodingKeys.self)
            padding = try container.decodeIfPresent(Int.self, forKey: .padding) ?? defaults.padding
            originX = try container.decodeIfPresent(Int.self, forKey: .originX) ?? defaults.originX
            originY = try container.decodeIfPresent(Int.self, forKey: .originY) ?? defaults.originY
            columns = try container.decodeIfPresent(Int.self, forKey: .columns) ?? defaults.columns
            rows = try container.decodeIfPresent(Int.self, forKey: .rows) ?? defaults.rows
        }
    }

    var theme: String
    var font: Font
    var window: Window

    enum CodingKeys: String, CodingKey {
        case theme
        case font
        case window
    }

    static var `default`: JusttyConfigFile {
        JusttyConfigFile(
            theme: Theme.defaultDarkThemeName,
            font: .default,
            window: .default
        )
    }

    init(theme: String, font: Font, window: Window) {
        self.theme = theme
        self.font = font
        self.window = window
    }

    init(from decoder: Decoder) throws {
        let defaults = JusttyConfigFile.default
        let container = try decoder.container(keyedBy: CodingKeys.self)
        theme = try container.decodeIfPresent(String.self, forKey: .theme) ?? defaults.theme
        font = try container.decodeIfPresent(Font.self, forKey: .font) ?? defaults.font
        window = try container.decodeIfPresent(Window.self, forKey: .window) ?? defaults.window
    }
}

enum JusttyConfigStore {
    /// XDG-style path: `~/.config/justty/config.yml`.
    static var defaultURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("justty", isDirectory: true)
            .appendingPathComponent("config.yml", isDirectory: false)
    }

    static func load(from url: URL) throws -> JusttyConfigFile {
        let data = try Data(contentsOf: url)
        let decoder = YAMLDecoder()
        return try decoder.decode(JusttyConfigFile.self, from: data)
    }

    /// Encodes and writes atomically (`config.yml.tmp` then replace).
    static func save(_ config: JusttyConfigFile, to url: URL) throws {
        let encoder = YAMLEncoder()
        let yaml = try encoder.encode(config)
        let parent = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: parent,
            withIntermediateDirectories: true
        )
        let tempURL = parent.appendingPathComponent("config.yml.tmp")
        try yaml.write(to: tempURL, atomically: true, encoding: .utf8)
        if FileManager.default.fileExists(atPath: url.path) {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: tempURL)
        } else {
            try FileManager.default.moveItem(at: tempURL, to: url)
        }
    }

    /// Creates parent dirs and writes `seeding` (or defaults) when the file is missing.
    @discardableResult
    static func ensureExists(
        at url: URL,
        seeding: JusttyConfigFile = .default
    ) throws -> JusttyConfigFile {
        if FileManager.default.fileExists(atPath: url.path) {
            return try load(from: url)
        }
        try save(seeding, to: url)
        return seeding
    }

    /// Opens the config in the default `.yml` app, else the default plain-text editor
    /// (Ghostty-style; often TextEdit).
    static func openInEditor(url: URL) {
        let workspace = NSWorkspace.shared
        let editor =
            workspace.urlForApplication(toOpen: url)
            ?? workspace.urlForApplication(toOpen: UTType.yaml)
            ?? workspace.urlForApplication(toOpen: UTType.plainText)
        if let editor {
            workspace.open(
                [url],
                withApplicationAt: editor,
                configuration: NSWorkspace.OpenConfiguration()
            )
        } else {
            workspace.open(url)
        }
    }
}
