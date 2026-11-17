//
//  TerminalConfiguration+Justty.swift
//  justty
//

import Darwin
import Foundation
import GhosttyTerminal
import GhosttyTheme

/// Ghostty configuration and launch helpers owned by the Justty host.
/// libghostty renders and runs the PTY; the host decides shell, env, keybinds,
/// and which Ghostty defaults to clear so app menus keep Cmd-T / Cmd-W.
enum JusttyTerminalConfig {
    static func terminalConfiguration(
        command: String,
        fontSize: Double? = nil
    ) -> TerminalConfiguration {
        let settings = AppSettings.shared
        let sanitized = TerminalFont.sanitizedFamily(settings.fontFamily)
        let family = sanitized.isEmpty
            ? TerminalFont.resolvedDefaultFamily : sanitized
        let resolvedSize = FontZoom.clamp(fontSize ?? settings.fontSize)
        return TerminalConfiguration { builder in
            builder.withFontFamily(family)
            builder.withFontSize(Float(resolvedSize))
            builder.withFontThicken(false)
            builder.withCustom("font-style", settings.fontWeight.fontStyle)
            builder.withCustom(
                "font-variation",
                "wght=\(settings.fontWeight.variationWeight)"
            )
            // Ghostty uses a relative cell-height adjustment, not a CSS multiplier.
            if let adjustment = cellHeightAdjustment(for: settings.lineHeight) {
                builder.withCustom("adjust-cell-height", adjustment)
            }
            builder.withCursorStyle(.block)
            builder.withCursorStyleBlink(true)
            builder.withWindowPaddingX(settings.terminalPadding)
            builder.withWindowPaddingY(settings.terminalPadding)
            builder.withCustom("window-padding-balance", "true")
            builder.withCustom("window-padding-color", "extend")
            // Clear Ghostty defaults so Cmd-T / Cmd-W stay with Justty.
            builder.withCustom("keybind", "clear")
            for keybind in ShortcutsCatalog.hostKeybinds {
                builder.withCustom("keybind", keybind)
            }
            builder.withCustom("command", "shell:\(command)")
            builder.withCustom("term", "xterm-256color")
            builder.withCustom("shell-integration", "none")
            builder.withCustom("scrollback-limit", JusttyConstants.scrollbackLimit)
            builder.withCustom("macos-option-as-alt", "true")
            builder.withCustom("scrollbar", "never")
            // Vendor confirmReadClipboard auto-approves, so "ask"/paste-protection
            // would be a false sense of security. Deny OSC 52 reads until a real UI exists.
            builder.withCustom("clipboard-read", "deny")
            builder.withCustom("clipboard-write", "allow")
            builder.withCustom("clipboard-paste-protection", "false")
        }
    }

    static func cellHeightAdjustment(for lineHeight: Double) -> String? {
        let percent = (lineHeight - 1.0) * 100
        guard percent != 0 else { return nil }
        // Raw Ghostty configuration requires ASCII numbers regardless of the UI locale.
        let formatted = percent.formatted(
            .number.locale(Locale(identifier: "en_US_POSIX"))
                .grouping(.never)
                .precision(.fractionLength(0...1))
        )
        return "\(formatted)%"
    }

    static func ghosttyTheme() -> GhosttyTerminal.TerminalTheme {
        GhosttyTerminal.TerminalTheme(
            light: Theme.lightTerminal().toTerminalConfiguration(),
            dark: Theme.darkTerminal().toTerminalConfiguration()
        )
    }

    static func surfaceEnvironment() -> [String: String] {
        var environment = [
            "TERM": "xterm-256color",
            "COLORTERM": "truecolor",
            "TERM_PROGRAM": "Justty",
        ]
        if let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String, !version.isEmpty {
            environment["TERM_PROGRAM_VERSION"] = version
        }
        if ProcessInfo.processInfo.environment["LANG"] == nil {
            environment["LANG"] = "en_US.UTF-8"
        }
        return environment
    }

    static func makeLaunchCommand(shellPath: String) -> String {
        let quoted = shellQuote(shellPath)
        return "/bin/sh -c \(shellQuote("exec \(quoted) -l"))"
    }

    static func loginShell() -> String {
        if let pw = getpwuid(getuid()), let shell = pw.pointee.pw_shell {
            let path = String(cString: shell)
            if !path.isEmpty { return path }
        }
        return ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
    }

    private static func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
