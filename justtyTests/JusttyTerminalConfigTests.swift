//
//  JusttyTerminalConfigTests.swift
//  justtyTests
//

import GhosttyTerminal
import Testing
@testable import Justty

struct JusttyTerminalConfigTests {
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
