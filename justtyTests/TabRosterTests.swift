//
//  TabRosterTests.swift
//  justtyTests
//

import Foundation
import Testing
@testable import Justty

struct TabRosterTests {
    @Test func addSelectsNewTab() {
        var roster = TabRoster()
        let a = UUID()
        let b = UUID()
        roster.add(a)
        #expect(roster.orderedIDs == [a])
        #expect(roster.selectedID == a)
        roster.add(b)
        #expect(roster.orderedIDs == [a, b])
        #expect(roster.selectedID == b)
    }

    @Test func selectIgnoresUnknownID() {
        var roster = TabRoster()
        let a = UUID()
        roster.add(a)
        roster.select(UUID())
        #expect(roster.selectedID == a)
    }

    @Test func selectNextAndPreviousWrap() {
        var roster = TabRoster()
        let a = UUID()
        let b = UUID()
        let c = UUID()
        roster.add(a)
        roster.add(b)
        roster.add(c)
        roster.select(a)

        roster.selectNext()
        #expect(roster.selectedID == b)
        roster.selectNext()
        #expect(roster.selectedID == c)
        roster.selectNext()
        #expect(roster.selectedID == a)

        roster.selectPrevious()
        #expect(roster.selectedID == c)
        roster.selectPrevious()
        #expect(roster.selectedID == b)
    }

    @Test func removeMiddleSelectsNeighbor() {
        var roster = TabRoster()
        let a = UUID()
        let b = UUID()
        let c = UUID()
        roster.add(a)
        roster.add(b)
        roster.add(c)
        roster.select(b)

        let outcome = roster.remove(id: b, fromShellExit: false)
        #expect(outcome == .remaining)
        #expect(roster.orderedIDs == [a, c])
        #expect(roster.selectedID == c)
    }

    @Test func removeFirstSelectsNext() {
        var roster = TabRoster()
        let a = UUID()
        let b = UUID()
        roster.add(a)
        roster.add(b)
        roster.select(a)

        let outcome = roster.remove(id: a, fromShellExit: false)
        #expect(outcome == .remaining)
        #expect(roster.selectedID == b)
    }

    @Test func removeLastSelectedSelectsPrevious() {
        var roster = TabRoster()
        let a = UUID()
        let b = UUID()
        roster.add(a)
        roster.add(b)

        let outcome = roster.remove(id: b, fromShellExit: false)
        #expect(outcome == .remaining)
        #expect(roster.selectedID == a)
    }

    @Test func removeNonSelectedKeepsSelection() {
        var roster = TabRoster()
        let a = UUID()
        let b = UUID()
        roster.add(a)
        roster.add(b)
        roster.select(a)

        let outcome = roster.remove(id: b, fromShellExit: false)
        #expect(outcome == .remaining)
        #expect(roster.selectedID == a)
    }

    @Test func userCloseLastTabDismissesWindow() {
        var roster = TabRoster()
        let a = UUID()
        roster.add(a)
        let outcome = roster.remove(id: a, fromShellExit: false)
        #expect(outcome == .dismissWindow)
        #expect(roster.orderedIDs.isEmpty)
        #expect(roster.selectedID == nil)
    }

    @Test func shellExitLastTabOpensReplacement() {
        var roster = TabRoster()
        let a = UUID()
        roster.add(a)
        let outcome = roster.remove(id: a, fromShellExit: true)
        #expect(outcome == .openReplacementTab)
        #expect(roster.orderedIDs.isEmpty)
        #expect(roster.selectedID == nil)
    }

    @Test func removeUnknownReturnsNotFound() {
        var roster = TabRoster()
        roster.add(UUID())
        #expect(roster.remove(id: UUID(), fromShellExit: false) == .notFound)
    }

    @Test func moveSelectedSwapsWithNeighbor() {
        var roster = TabRoster()
        let a = UUID()
        let b = UUID()
        let c = UUID()
        roster.add(a)
        roster.add(b)
        roster.add(c)
        roster.select(b)

        roster.moveSelected(by: -1)
        #expect(roster.orderedIDs == [b, a, c])
        #expect(roster.selectedID == b)

        roster.moveSelected(by: 1)
        #expect(roster.orderedIDs == [a, b, c])
        #expect(roster.selectedID == b)

        roster.moveSelected(by: 1)
        #expect(roster.orderedIDs == [a, c, b])
        #expect(roster.selectedID == b)
    }

    @Test func moveSelectedNoOpsAtEnds() {
        var roster = TabRoster()
        let a = UUID()
        let b = UUID()
        roster.add(a)
        roster.add(b)
        roster.select(a)

        roster.moveSelected(by: -1)
        #expect(roster.orderedIDs == [a, b])
        #expect(roster.selectedID == a)

        roster.select(b)
        roster.moveSelected(by: 1)
        #expect(roster.orderedIDs == [a, b])
        #expect(roster.selectedID == b)
    }

    @Test func moveSelectedNoOpsWithoutSelection() {
        var roster = TabRoster()
        roster.moveSelected(by: 1)
        #expect(roster.orderedIDs.isEmpty)
        #expect(roster.selectedID == nil)
    }
}
