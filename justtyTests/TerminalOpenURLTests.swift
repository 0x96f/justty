//
//  TerminalOpenURLTests.swift
//  justtyTests
//

import Testing
@testable import Justty

struct TerminalOpenURLTests {
    @Test func allowsHttpHttpsMailto() {
        #expect(TerminalSession.allowedOpenURL("https://example.com") != nil)
        #expect(TerminalSession.allowedOpenURL("http://example.com/path") != nil)
        #expect(TerminalSession.allowedOpenURL("mailto:hi@example.com") != nil)
    }

    @Test func rejectsFileAndCustomSchemes() {
        #expect(TerminalSession.allowedOpenURL("file:///etc/passwd") == nil)
        #expect(TerminalSession.allowedOpenURL("smb://host/share") == nil)
        #expect(TerminalSession.allowedOpenURL("javascript:alert(1)") == nil)
        #expect(TerminalSession.allowedOpenURL("not a url") == nil)
    }
}
