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
    static func terminalConfiguration(command: String) -> TerminalConfiguration {
        let settings = AppSettings.shared
        let family = settings.fontFamily.isEmpty
            ? TerminalFont.resolvedDefaultFamily : settings.fontFamily
        return TerminalConfiguration { builder in
            builder.withFontFamily(family)
            builder.withFontSize(Float(settings.fontSize))
            builder.withFontThicken(false)
            builder.withCustom("font-style", settings.fontWeight.fontStyle)
            builder.withCustom(
                "font-variation",
                "wght=\(settings.fontWeight.variationWeight)"
            )
            // Ghostty uses a relative cell-height adjustment, not a CSS multiplier.
            let cellHeightPercent = (settings.lineHeight - 1.0) * 100
            if cellHeightPercent != 0 {
                let formatted = cellHeightPercent.formatted(
                    .number.precision(.fractionLength(0...1))
                )
                builder.withCustom("adjust-cell-height", "\(formatted)%")
            }
            builder.withCursorStyle(.block)
            builder.withCursorStyleBlink(true)
            builder.withWindowPaddingX(settings.terminalPadding)
            builder.withWindowPaddingY(settings.terminalPadding)
            builder.withCustom("window-padding-balance", "true")
            builder.withCustom("window-padding-color", "extend")
            // Clear Ghostty defaults so Cmd-T / Cmd-W stay with Justty.
            builder.withCustom("keybind", "clear")
            for keybind in hostKeybinds {
                builder.withCustom("keybind", keybind)
            }
            builder.withCustom("command", "shell:\(command)")
            builder.withCustom("term", "xterm-256color")
            builder.withCustom("shell-integration", "none")
            builder.withCustom("scrollback-limit", JusttyConstants.scrollbackLimit)
            builder.withCustom("macos-option-as-alt", "true")
            builder.withCustom("scrollbar", "never")
            builder.withCustom("clipboard-read", "ask")
            builder.withCustom("clipboard-write", "allow")
            builder.withCustom("clipboard-paste-protection", "true")
        }
    }

    static func ghosttyTheme() -> GhosttyTerminal.TerminalTheme {
        let config = Theme.terminal().toTerminalConfiguration()
        // API requires both slots; the host always uses the same chosen theme.
        return GhosttyTerminal.TerminalTheme(light: config, dark: config)
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

    private static let hostKeybinds = [
        "alt+left=esc:b",
        "alt+right=esc:f",
        "super+left=text:\\x01",
        "super+right=text:\\x05",
        "super+backspace=text:\\x15",
        "super+c=copy_to_clipboard",
        "super+v=paste_from_clipboard",
        "super+home=scroll_to_top",
        "super+end=scroll_to_bottom",
        "super+page_up=scroll_page_up",
        "super+page_down=scroll_page_down",
    ]

    private static func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
