//
//  ProcessWorkingDirectoryTests.swift
//  justtyTests
//

import Darwin
import Foundation
import Testing
@testable import Justty

struct ProcessWorkingDirectoryTests {
    @Test func prefersReportedPathWhenUsable() {
        let path = ProcessWorkingDirectory.resolve(
            reportedPath: "/tmp",
            shellPid: nil,
            foregroundPid: nil,
            home: "/Users/test",
            processCwd: { _ in "/var" },
            isDirectory: { $0 == "/tmp" }
        )
        #expect(path == "/tmp")
    }

    @Test func fallsBackToShellPidCwd() {
        let path = ProcessWorkingDirectory.resolve(
            reportedPath: nil,
            shellPid: 42,
            foregroundPid: 99,
            home: "/Users/test",
            processCwd: { pid in pid == 42 ? "/opt/project" : nil },
            isDirectory: { $0 == "/opt/project" }
        )
        #expect(path == "/opt/project")
    }

    @Test func fallsBackToForegroundWhenShellMissing() {
        let path = ProcessWorkingDirectory.resolve(
            reportedPath: "/missing",
            shellPid: nil,
            foregroundPid: 7,
            home: "/Users/test",
            processCwd: { pid in pid == 7 ? "/work" : nil },
            isDirectory: { $0 == "/work" }
        )
        #expect(path == "/work")
    }

    @Test func fallsBackToHomeWhenNothingUsable() {
        let path = ProcessWorkingDirectory.resolve(
            reportedPath: "/nope",
            shellPid: 1,
            foregroundPid: 2,
            home: "/Users/test",
            processCwd: { _ in nil },
            isDirectory: { _ in false }
        )
        #expect(path == "/Users/test")
    }

    @Test func ignoresUnusableReportedPath() {
        let path = ProcessWorkingDirectory.resolve(
            reportedPath: "/gone",
            shellPid: 3,
            foregroundPid: nil,
            home: "/Users/test",
            processCwd: { _ in "/alive" },
            isDirectory: { $0 == "/alive" }
        )
        #expect(path == "/alive")
    }

    @Test func cwdOfCurrentProcessMatchesFileManager() throws {
        let pid = getpid()
        let resolved = try #require(ProcessWorkingDirectory.cwd(of: pid))
        let expected = FileManager.default.currentDirectoryPath
        #expect(resolved == expected)
    }

    @Test func newTabInheritsSelectedDirectory() {
        let inherited = TabManager.workingDirectoryForNewTab(
            inheritingCwd: true,
            selected: "/proj",
            home: "/Users/test"
        )
        #expect(inherited == "/proj")
    }

    @Test func newTabWithoutSelectionUsesHome() {
        let home = TabManager.workingDirectoryForNewTab(
            inheritingCwd: true,
            selected: nil,
            home: "/Users/test"
        )
        #expect(home == "/Users/test")
    }

    @Test func replacementTabDoesNotInherit() {
        let home = TabManager.workingDirectoryForNewTab(
            inheritingCwd: false,
            selected: "/proj",
            home: "/Users/test"
        )
        #expect(home == "/Users/test")
    }
}
