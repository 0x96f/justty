//
//  ShortcutsCatalogTests.swift
//  justtyTests
//

import Testing
@testable import Justty

struct ShortcutsCatalogTests {
    @Test func hostKeybindsAreNonEmpty() {
        #expect(!ShortcutsCatalog.hostKeybinds.isEmpty)
    }

    @Test func menuOnlyShortcutsHaveNoGhosttyKeybind() throws {
        let items = ShortcutsCatalog.sections.flatMap(\.items)
        let menuOnlyIDs = ["new-window", "new-tab", "close-tab", "next-tab", "prev-tab"]
        for id in menuOnlyIDs {
            let item = try #require(items.first { $0.id == id })
            #expect(item.ghosttyKeybind == nil)
        }
    }

    @Test func terminalShortcutsHaveGhosttyKeybinds() throws {
        let terminal = try #require(
            ShortcutsCatalog.sections.first { $0.id == "terminal" }
        )
        for item in terminal.items {
            #expect(item.ghosttyKeybind != nil)
        }
    }

    @Test func hostKeybindsAreUnique() {
        let binds = ShortcutsCatalog.hostKeybinds
        #expect(Set(binds).count == binds.count)
    }
}
