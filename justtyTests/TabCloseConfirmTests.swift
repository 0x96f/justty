//
//  TabCloseConfirmTests.swift
//  justtyTests
//

import Testing
@testable import Justty

@MainActor
struct TabCloseConfirmTests {
    @Test func shouldConfirmCloseRequiresAllGates() {
        #expect(
            TabManager.shouldConfirmClose(
                fromShellExit: false,
                skipConfirm: false,
                hasRunningCommand: true,
                confirmEnabled: true
            )
        )
        #expect(
            !TabManager.shouldConfirmClose(
                fromShellExit: true,
                skipConfirm: false,
                hasRunningCommand: true,
                confirmEnabled: true
            )
        )
        #expect(
            !TabManager.shouldConfirmClose(
                fromShellExit: false,
                skipConfirm: true,
                hasRunningCommand: true,
                confirmEnabled: true
            )
        )
        #expect(
            !TabManager.shouldConfirmClose(
                fromShellExit: false,
                skipConfirm: false,
                hasRunningCommand: false,
                confirmEnabled: true
            )
        )
        #expect(
            !TabManager.shouldConfirmClose(
                fromShellExit: false,
                skipConfirm: false,
                hasRunningCommand: true,
                confirmEnabled: false
            )
        )
    }

    @Test func busyCloseSkipsConfirmWhenPreferenceOff() throws {
        var confirmCount = 0
        let tabs = TabManager(
            createInitialTab: false,
            confirmClose: { _, _ in confirmCount += 1 },
            closeWindow: { _ in },
            shouldConfirmBusyClose: { false },
            isSessionBusy: { _ in true }
        )
        tabs.newTab(inheritingCwd: false)
        let session = try #require(tabs.sessions.first)

        tabs.close(session)

        #expect(confirmCount == 0)
        #expect(tabs.sessions.isEmpty)
    }

    @Test func busyCloseInvokesConfirmWhenPreferenceOn() throws {
        var confirmCount = 0
        let tabs = TabManager(
            createInitialTab: false,
            confirmClose: { _, _ in confirmCount += 1 },
            closeWindow: { _ in },
            shouldConfirmBusyClose: { true },
            isSessionBusy: { _ in true }
        )
        tabs.newTab(inheritingCwd: false)
        let session = try #require(tabs.sessions.first)

        tabs.close(session)

        #expect(confirmCount == 1)
        #expect(tabs.sessions.count == 1)
        #expect(tabs.sessions.first?.id == session.id)
    }
}
