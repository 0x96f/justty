//
//  TerminalFindTests.swift
//  justtyTests
//

import Testing
@testable import Justty

struct TerminalFindTests {
    @Test func searchActionIncludesQuery() {
        #expect(TerminalFind.searchAction(for: "error") == "search:error")
    }

    @Test func searchActionAllowsEmptyQuery() {
        #expect(TerminalFind.searchAction(for: "") == "search:")
    }

    @Test func navigateAndEndActions() {
        #expect(TerminalFind.navigateNext == "navigate_search:next")
        #expect(TerminalFind.navigatePrevious == "navigate_search:previous")
        #expect(TerminalFind.end == "end_search")
    }

    @Test @MainActor func showAndHideFindUpdatesState() {
        // No initial tab: avoid spawning a login shell in unit tests.
        let tabs = TabManager(createInitialTab: false)
        #expect(!tabs.isFindPresented)

        tabs.showFind()
        #expect(tabs.isFindPresented)
        let token = tabs.findFocusToken

        tabs.updateFindQuery("foo")
        #expect(tabs.findQuery == "foo")

        tabs.showFind()
        #expect(tabs.findFocusToken == token &+ 1)

        tabs.hideFind()
        #expect(!tabs.isFindPresented)
        #expect(tabs.findQuery.isEmpty)
    }

    @Test @MainActor func selectNextWhileFindClosedLeavesFindIdle() {
        let tabs = TabManager(createInitialTab: false)
        tabs.selectNext()
        #expect(!tabs.isFindPresented)
        #expect(tabs.findQuery.isEmpty)
    }

    @Test @MainActor func selectNextDismissesOpenFind() {
        let tabs = TabManager(createInitialTab: false)
        tabs.showFind()
        tabs.updateFindQuery("bar")
        tabs.selectNext()
        #expect(!tabs.isFindPresented)
        #expect(tabs.findQuery.isEmpty)
    }
}
