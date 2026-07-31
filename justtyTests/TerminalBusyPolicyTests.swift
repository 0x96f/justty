//
//  TerminalBusyPolicyTests.swift
//  justtyTests
//

import Darwin
import Testing
@testable import Justty

@MainActor
struct TerminalBusyPolicyTests {
    @Test func nilForegroundIsNotBusy() {
        let result = TerminalSession.hasRunningCommand(
            foregroundPid: nil,
            foregroundName: nil,
            shellName: "zsh",
            shellPid: 42
        )
        #expect(result.isBusy == false)
        #expect(result.lockedShellPid == nil)
    }

    @Test func idleShellLocksPidAndIsNotBusy() {
        let result = TerminalSession.hasRunningCommand(
            foregroundPid: 100,
            foregroundName: "zsh",
            shellName: "zsh",
            shellPid: nil
        )
        #expect(result.isBusy == false)
        #expect(result.lockedShellPid == 100)
    }

    @Test func otherProcessIsBusyWhenShellPidKnown() {
        let result = TerminalSession.hasRunningCommand(
            foregroundPid: 200,
            foregroundName: "vim",
            shellName: "zsh",
            shellPid: 100
        )
        #expect(result.isBusy == true)
        #expect(result.lockedShellPid == nil)
    }

    @Test func sameShellPidIsNotBusy() {
        let result = TerminalSession.hasRunningCommand(
            foregroundPid: 100,
            foregroundName: "zsh",
            shellName: "zsh",
            shellPid: 100
        )
        #expect(result.isBusy == false)
        #expect(result.lockedShellPid == 100)
    }

    @Test func launchShWrapperIsIgnoredBeforeShellLock() {
        let result = TerminalSession.hasRunningCommand(
            foregroundPid: 50,
            foregroundName: "sh",
            shellName: "zsh",
            shellPid: nil
        )
        #expect(result.isBusy == false)
        #expect(result.lockedShellPid == nil)
    }

    @Test func unknownNonShellForegroundIsBusyBeforeShellLock() {
        let result = TerminalSession.hasRunningCommand(
            foregroundPid: 50,
            foregroundName: "python",
            shellName: "zsh",
            shellPid: nil
        )
        #expect(result.isBusy == true)
        #expect(result.lockedShellPid == nil)
    }

    @Test func displayTitleIdleUsesShell() {
        let title = TerminalSession.displayTitle(
            isBusy: false,
            foregroundName: "zsh",
            shellName: "zsh"
        )
        #expect(title == "zsh")
    }

    @Test func displayTitleBusyUsesForegroundBasename() {
        let title = TerminalSession.displayTitle(
            isBusy: true,
            foregroundName: "node",
            shellName: "zsh"
        )
        #expect(title == "node")
    }

    @Test func displayTitleBusyWithNilNameFallsBackToShell() {
        let title = TerminalSession.displayTitle(
            isBusy: true,
            foregroundName: nil,
            shellName: "zsh"
        )
        #expect(title == "zsh")
    }

    @Test func displayTitleIdleAfterBusyUsesShell() {
        let busy = TerminalSession.displayTitle(
            isBusy: true,
            foregroundName: "vim",
            shellName: "zsh"
        )
        let idle = TerminalSession.displayTitle(
            isBusy: false,
            foregroundName: "zsh",
            shellName: "zsh"
        )
        #expect(busy == "vim")
        #expect(idle == "zsh")
    }

    @Test func displayTitleBusyPrefersOscOverProcess() {
        let title = TerminalSession.displayTitle(
            isBusy: true,
            foregroundName: "node",
            shellName: "zsh",
            oscTitle: "Cursor Agent"
        )
        #expect(title == "Cursor Agent")
    }

    @Test func displayTitleIdleIgnoresOsc() {
        let title = TerminalSession.displayTitle(
            isBusy: false,
            foregroundName: "zsh",
            shellName: "zsh",
            oscTitle: "Cursor Agent"
        )
        #expect(title == "zsh")
    }

    @Test func displayTitleBusyEmptyOscFallsBackToProcess() {
        let title = TerminalSession.displayTitle(
            isBusy: true,
            foregroundName: "node",
            shellName: "zsh",
            oscTitle: ""
        )
        #expect(title == "node")
    }

    @Test func displayTitleIdleWithDirectoryPrefixesShell() {
        let title = TerminalSession.displayTitle(
            isBusy: false,
            foregroundName: "zsh",
            shellName: "zsh",
            directoryName: "dir"
        )
        #expect(title == "dir - zsh")
    }

    @Test func displayTitleBusyWithDirectoryPrefixesProcess() {
        let title = TerminalSession.displayTitle(
            isBusy: true,
            foregroundName: "node",
            shellName: "zsh",
            directoryName: "dir"
        )
        #expect(title == "dir - node")
    }

    @Test func displayTitleBusyWithDirectoryPrefixesOsc() {
        let title = TerminalSession.displayTitle(
            isBusy: true,
            foregroundName: "node",
            shellName: "zsh",
            oscTitle: "Cursor Agent",
            directoryName: "dir"
        )
        #expect(title == "dir - Cursor Agent")
    }

    @Test func displayTitleEmptyDirectoryKeepsBaseLabel() {
        let title = TerminalSession.displayTitle(
            isBusy: true,
            foregroundName: "node",
            shellName: "zsh",
            directoryName: ""
        )
        #expect(title == "node")
    }

    @Test func displayTitleNilDirectoryKeepsBaseLabel() {
        let title = TerminalSession.displayTitle(
            isBusy: false,
            foregroundName: "zsh",
            shellName: "zsh",
            directoryName: nil
        )
        #expect(title == "zsh")
    }
}
