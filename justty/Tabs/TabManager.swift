//
//  TabManager.swift
//  justty
//

import AppKit
import Combine
import Foundation

@MainActor
final class TabManager: ObservableObject {
    @Published private(set) var sessions: [TerminalSession] = []
    @Published private(set) var selectedID: TerminalSession.ID?
    @Published private(set) var isFindPresented = false
    @Published private(set) var findQuery = ""
    /// Bumped when Find should re-focus the query field (e.g. ⌘F while already open).
    @Published private(set) var findFocusToken = 0

    var selectedSession: TerminalSession? {
        sessions.first { $0.id == selectedID }
    }

    var parkedSessions: [TerminalSession] {
        sessions.filter { $0.id != selectedID }
    }

    private var roster = TabRoster()
    private var cancellables = Set<AnyCancellable>()
    private let makeSession: (String) -> TerminalSession
    private let confirmCloseHandler: (TerminalSession, @escaping () -> Void) -> Void
    private let closeWindowHandler: (NSWindow?) -> Void

    init(
        makeSession: ((String) -> TerminalSession)? = nil,
        createInitialTab: Bool = true,
        confirmClose: ((TerminalSession, @escaping () -> Void) -> Void)? = nil,
        closeWindow: ((NSWindow?) -> Void)? = nil
    ) {
        self.makeSession = makeSession ?? { TerminalSession(workingDirectory: $0) }
        self.closeWindowHandler = closeWindow ?? { window in
            DispatchQueue.main.async { window?.close() }
        }
        self.confirmCloseHandler = confirmClose ?? Self.defaultConfirmClose

        if createInitialTab {
            newTab(inheritingCwd: false)
        }
        NotificationCenter.default.publisher(for: .justtySettingsDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshAppearance() }
            .store(in: &cancellables)
    }

    /// Opens a tab. When `inheritingCwd` is true, launches in the selected tab's cwd.
    func newTab(inheritingCwd: Bool = true) {
        dismissFindIfNeeded()
        let cwd = Self.workingDirectoryForNewTab(
            inheritingCwd: inheritingCwd,
            selected: selectedSession?.resolvedWorkingDirectory
        )
        let session = makeSession(cwd)
        session.onExited = { [weak self] exited in
            self?.close(exited, fromShellExit: true)
        }
        sessions.append(session)
        roster.add(session.id)
        selectedID = roster.selectedID
    }

    /// Pure policy for which directory a new tab should launch in.
    static func workingDirectoryForNewTab(
        inheritingCwd: Bool,
        selected: String?,
        home: String = NSHomeDirectory()
    ) -> String {
        if inheritingCwd, let selected {
            return selected
        }
        return home
    }

    func select(_ id: TerminalSession.ID) {
        if id != selectedID {
            dismissFindIfNeeded()
        }
        roster.select(id)
        selectedID = roster.selectedID
    }

    func closeSelected() {
        guard let selectedSession else { return }
        close(selectedSession)
    }

    func close(
        _ session: TerminalSession,
        fromShellExit: Bool = false,
        skipConfirm: Bool = false
    ) {
        if !fromShellExit, !skipConfirm, session.hasRunningCommand {
            confirmCloseHandler(session) { [weak self] in
                self?.close(session, skipConfirm: true)
            }
            return
        }

        guard sessions.contains(where: { $0.id == session.id }) else {
            return
        }

        if session.id == selectedID {
            dismissFindIfNeeded()
        }

        // Capture before teardown: after terminate the view may leave the hierarchy,
        // and SwiftUI dismiss() is unreliable from an NSAlert sheet completion.
        let shouldCloseWindow = sessions.count == 1 && !fromShellExit
        let windowToClose = shouldCloseWindow
            ? (session.terminalView.window ?? NSApp.keyWindow)
            : nil

        // Drop from the array before terminate so any late surface-close
        // callback cannot re-enter and remove(at:) with a stale index.
        sessions.removeAll { $0.id == session.id }
        let outcome = roster.remove(id: session.id, fromShellExit: fromShellExit)
        selectedID = roster.selectedID

        if !fromShellExit, !session.hasExited {
            session.terminate()
        }

        switch outcome {
        case .openReplacementTab:
            // Shell exit keeps the window alive with a fresh tab at home.
            newTab(inheritingCwd: false)
        case .dismissWindow:
            closeWindowHandler(windowToClose)
        case .remaining, .notFound:
            break
        }
    }

    func selectNext() {
        dismissFindIfNeeded()
        roster.selectNext()
        selectedID = roster.selectedID
    }

    func selectPrevious() {
        dismissFindIfNeeded()
        roster.selectPrevious()
        selectedID = roster.selectedID
    }

    func refreshAppearance() {
        for session in sessions {
            session.applyAppearance(clearFontZoom: true)
        }
    }

    func increaseFontSize() {
        selectedSession?.increaseFontSize()
    }

    func decreaseFontSize() {
        selectedSession?.decreaseFontSize()
    }

    func resetFontSize() {
        selectedSession?.resetFontSize()
    }

    // MARK: - Find

    func showFind() {
        isFindPresented = true
        findFocusToken &+= 1
        applyFindQuery()
    }

    func hideFind(endSearch: Bool = true) {
        if endSearch {
            endSearchOnSelected()
        }
        isFindPresented = false
        findQuery = ""
    }

    func updateFindQuery(_ query: String) {
        findQuery = query
        applyFindQuery()
    }

    func findNext() {
        guard isFindPresented, !findQuery.isEmpty else { return }
        selectedSession?.performFindNext()
    }

    func findPrevious() {
        guard isFindPresented, !findQuery.isEmpty else { return }
        selectedSession?.performFindPrevious()
    }

    /// Ends Ghostty search and closes the find bar only when find is open.
    private func dismissFindIfNeeded() {
        guard isFindPresented else { return }
        hideFind(endSearch: true)
    }

    private func applyFindQuery() {
        guard isFindPresented, let session = selectedSession else { return }
        session.performFindSearch(findQuery)
    }

    private func endSearchOnSelected() {
        selectedSession?.endFindSearch()
    }

    private static func defaultConfirmClose(
        _ session: TerminalSession,
        onConfirm: @escaping () -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = "Close this tab?"
        alert.informativeText =
            "You have a running process in this tab. Closing it will terminate the process."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Close")
        alert.addButton(withTitle: "Cancel")

        let respond: (NSApplication.ModalResponse) -> Void = { response in
            guard response == .alertFirstButtonReturn else { return }
            // Let the sheet finish dismissing before closing tab/window.
            DispatchQueue.main.async {
                onConfirm()
            }
        }

        if let window = session.terminalView.window ?? NSApp.keyWindow {
            alert.beginSheetModal(for: window, completionHandler: respond)
        } else {
            respond(alert.runModal())
        }
    }
}
