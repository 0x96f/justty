//
//  TabRoster.swift
//  justty
//

import Foundation

/// Pure tab order and selection rules used by `TabManager`.
/// Keeps close/next/prev index math free of PTY and AppKit.
struct TabRoster {
    enum RemoveOutcome: Equatable {
        /// List still has tabs; `selectedID` is the post-remove selection.
        case remaining
        /// Last tab exited from the shell — host should open a replacement tab.
        case openReplacementTab
        /// User closed the last tab — host should dismiss the window.
        case dismissWindow
        /// ID was not in the roster.
        case notFound
    }

    private(set) var orderedIDs: [UUID] = []
    private(set) var selectedID: UUID?

    mutating func add(_ id: UUID) {
        orderedIDs.append(id)
        selectedID = id
    }

    mutating func select(_ id: UUID) {
        guard orderedIDs.contains(id) else { return }
        selectedID = id
    }

    mutating func selectNext() {
        guard let selectedID,
              let index = orderedIDs.firstIndex(of: selectedID),
              !orderedIDs.isEmpty
        else { return }
        self.selectedID = orderedIDs[(index + 1) % orderedIDs.count]
    }

    mutating func selectPrevious() {
        guard let selectedID,
              let index = orderedIDs.firstIndex(of: selectedID),
              !orderedIDs.isEmpty
        else { return }
        self.selectedID = orderedIDs[(index - 1 + orderedIDs.count) % orderedIDs.count]
    }

    /// Removes `id` and updates selection to mirror `TabManager.close`.
    mutating func remove(id: UUID, fromShellExit: Bool) -> RemoveOutcome {
        guard let index = orderedIDs.firstIndex(of: id) else {
            return .notFound
        }

        let wasSelected = selectedID == id
        orderedIDs.remove(at: index)

        if orderedIDs.isEmpty {
            selectedID = nil
            return fromShellExit ? .openReplacementTab : .dismissWindow
        }

        if wasSelected {
            let nextIndex = min(index, orderedIDs.count - 1)
            selectedID = orderedIDs[nextIndex]
        }
        return .remaining
    }
}
