//
//  TerminalFontSanitizeTests.swift
//  justtyTests
//

import Testing
@testable import Justty

struct TerminalFontSanitizeTests {
    @Test func emptyAndWhitespaceBecomeEmpty() {
        #expect(TerminalFont.sanitizedFamily("", allowed: ["Menlo"]) == "")
        #expect(TerminalFont.sanitizedFamily("  ", allowed: ["Menlo"]) == "")
    }

    @Test func acceptsAllowlistedFamily() {
        #expect(TerminalFont.sanitizedFamily("Menlo", allowed: ["Menlo", "SF Mono"]) == "Menlo")
    }

    @Test func rejectsUnknownAndInjectedValues() {
        #expect(TerminalFont.sanitizedFamily("Comic Sans", allowed: ["Menlo"]) == "")
        #expect(
            TerminalFont.sanitizedFamily(
                "Menlo\ncommand = evil",
                allowed: ["Menlo", "Menlo\ncommand = evil"]
            ) == ""
        )
        #expect(
            TerminalFont.sanitizedFamily(
                "Menlo\u{0000}x",
                allowed: ["Menlo\u{0000}x"]
            ) == ""
        )
    }
}
