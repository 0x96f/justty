//
//  TerminalFind.swift
//  justty
//

import Foundation

/// Ghostty binding-action strings for host-driven scrollback search.
enum TerminalFind {
    static func searchAction(for query: String) -> String {
        "search:\(query)"
    }

    static let navigateNext = "navigate_search:next"
    static let navigatePrevious = "navigate_search:previous"
    static let end = "end_search"
}
