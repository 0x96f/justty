//
//  TerminalBusyPolicyTests.swift
//  justtyTests
//

import Darwin
import Foundation
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

    @Test func sameNameChildShellIsBusyWithoutReplacingLoginShellPid() {
        let result = TerminalSession.hasRunningCommand(
            foregroundPid: 200,
            foregroundName: "zsh",
            shellName: "zsh",
            shellPid: 100
        )
        #expect(result.isBusy)
        #expect(result.lockedShellPid == nil)
        #expect(TabManager.shouldConfirmClose(
            fromShellExit: false,
            skipConfirm: false,
            hasRunningCommand: result.isBusy,
            confirmEnabled: true
        ))
    }

    @Test func knownShellPidDoesNotRequireProcessName() {
        let result = TerminalSession.hasRunningCommand(
            foregroundPid: 100,
            foregroundName: nil,
            shellName: "zsh",
            shellPid: 100
        )
        #expect(!result.isBusy)
        #expect(result.lockedShellPid == 100)
    }

    @Test func exitedStartupChildAllowsLoginShellRediscovery() {
        var shellPid: pid_t?
        #expect(!TerminalSession.updateBusyState(
            foregroundPid: 200,
            foregroundName: "zsh",
            shellName: "zsh",
            shellPid: &shellPid,
            isKnownDead: { _ in
                Issue.record("No PID should be probed before shell discovery")
                return false
            }
        ))
        #expect(shellPid == 200)

        #expect(!TerminalSession.updateBusyState(
            foregroundPid: 100,
            foregroundName: "zsh",
            shellName: "zsh",
            shellPid: &shellPid,
            isKnownDead: { $0 == 200 }
        ))
        #expect(shellPid == 100)

        // A living login shell must stay recorded when another shell runs.
        #expect(TerminalSession.updateBusyState(
            foregroundPid: 300,
            foregroundName: "zsh",
            shellName: "zsh",
            shellPid: &shellPid,
            isKnownDead: { _ in false }
        ))
        #expect(shellPid == 100)

        #expect(!TerminalSession.updateBusyState(
            foregroundPid: 100,
            foregroundName: "zsh",
            shellName: "zsh",
            shellPid: &shellPid,
            isKnownDead: { _ in
                Issue.record("The known foreground shell needs no liveness probe")
                return true
            }
        ))
        #expect(shellPid == 100)
    }

    @Test func uncertainShellLivenessPreservesKnownPid() {
        var shellPid: pid_t? = 100
        #expect(TerminalSession.updateBusyState(
            foregroundPid: 200,
            foregroundName: "zsh",
            shellName: "zsh",
            shellPid: &shellPid,
            isKnownDead: { _ in false }
        ))
        #expect(shellPid == 100)
    }

    @Test func abandonedSessionInvalidatesPollingTimerOnNextTick() async throws {
        var session: TerminalSession? = TerminalSession()
        weak var releasedSession = session
        let timer = try #require(session?.titlePollTimer)
        session = nil
        #expect(releasedSession == nil)

        timer.fire()
        // The timer dispatches its owner check onto the main actor.
        for _ in 0..<100 where timer.isValid {
            await Task.yield()
        }
        #expect(!timer.isValid)
        timer.invalidate()
    }

    @Test func unmountedSessionKeepsPollingUntilExplicitTermination() async throws {
        let session = TerminalSession()
        let timer = try #require(session.titlePollTimer)
        defer { session.terminate() }
        timer.fire()
        await Task.yield()
        #expect(timer.isValid)

        session.terminate()
        #expect(!timer.isValid)
        #expect(session.titlePollTimer == nil)
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
