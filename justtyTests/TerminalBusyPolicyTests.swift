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
}
