//
//  JusttyTerminalConfigTests.swift
//  justtyTests
//

import GhosttyTerminal
import Testing
@testable import Justty

struct JusttyTerminalConfigTests {
    @Test(arguments: [(1.234, "23.4%"), (0.876, "-12.4%"), (1.05, "5%")])
    @MainActor func cellHeightUsesGhosttyNumericSyntax(lineHeight: Double, expected: String) throws {
        let adjustment = try #require(JusttyTerminalConfig.cellHeightAdjustment(for: lineHeight))
        #expect(adjustment == expected)
        let configuration = TerminalConfiguration { builder in
            builder.withCustom("adjust-cell-height", adjustment)
        }
        let controller = TerminalController(
            configSource: .none,
            terminalConfiguration: configuration
        )
        #expect(controller.lastConfigurationIssue == nil)
    }

    @Test func defaultLineHeightNeedsNoAdjustment() {
        #expect(JusttyTerminalConfig.cellHeightAdjustment(for: 1) == nil)
    }

    @Test @MainActor func hostConfigurationIsAcceptedByLibghostty() {
        // Raw Ghostty keys can change independently of the Swift wrapper API.
        let controller = TerminalController(
            configSource: .none,
            theme: JusttyTerminalConfig.ghosttyTheme(),
            terminalConfiguration: JusttyTerminalConfig.terminalConfiguration(
                command: JusttyTerminalConfig.makeLaunchCommand(shellPath: "/bin/zsh")
            )
        )
        #expect(controller.lastConfigurationIssue == nil)
    }

    @Test func makeLaunchCommandForPlainPath() {
        let command = JusttyTerminalConfig.makeLaunchCommand(shellPath: "/bin/zsh")
        #expect(command == "/bin/sh -c 'exec '\\''/bin/zsh'\\'' -l'")
    }

    @Test func makeLaunchCommandForPathWithSpaces() {
        let command = JusttyTerminalConfig.makeLaunchCommand(
            shellPath: "/opt/my shell/zsh"
        )
        #expect(command == "/bin/sh -c 'exec '\\''/opt/my shell/zsh'\\'' -l'")
    }

    @Test func makeLaunchCommandForPathWithSingleQuote() {
        let command = JusttyTerminalConfig.makeLaunchCommand(shellPath: "/tmp/it's")
        // Nested single-quote escaping: ' → '\'' inside the /bin/sh -c payload.
        #expect(command.hasPrefix("/bin/sh -c "))
        #expect(command.contains("/tmp/it"))
        #expect(command.contains("\\'"))
        #expect(command.hasSuffix(" -l'"))
    }

    @Test func ghosttyThemeKeepsSeparateLightAndDarkSlots() {
        Theme.reloadSelection(
            themeMode: .dark,
            lightThemeName: Theme.defaultLightThemeName,
            darkThemeName: Theme.defaultDarkThemeName
        )

        let theme = JusttyTerminalConfig.ghosttyTheme()
        #expect(theme.light != theme.dark)
    }
}
