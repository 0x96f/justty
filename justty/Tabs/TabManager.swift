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

    var selectedSession: TerminalSession? {
        sessions.first { $0.id == selectedID }
    }

    var parkedSessions: [TerminalSession] {
        sessions.filter { $0.id != selectedID }
    }

    private var roster = TabRoster()
    private var cancellables = Set<AnyCancellable>()
    private let makeSession: () -> TerminalSession
    private let confirmCloseHandler: (TerminalSession, @escaping () -> Void) -> Void
    private let closeWindowHandler: (NSWindow?) -> Void

    init(
        makeSession: (() -> TerminalSession)? = nil,
        createInitialTab: Bool = true,
        confirmClose: ((TerminalSession, @escaping () -> Void) -> Void)? = nil,
        closeWindow: ((NSWindow?) -> Void)? = nil
    ) {
        self.makeSession = makeSession ?? { TerminalSession() }
        self.closeWindowHandler = closeWindow ?? { window in
            DispatchQueue.main.async { window?.close() }
        }
        self.confirmCloseHandler = confirmClose ?? Self.defaultConfirmClose

        if createInitialTab {
            newTab()
        }
        NotificationCenter.default.publisher(for: .justtySettingsDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshAppearance() }
            .store(in: &cancellables)
    }

    func newTab() {
        let session = makeSession()
        session.onExited = { [weak self] exited in
            self?.close(exited, fromShellExit: true)
        }
        sessions.append(session)
        roster.add(session.id)
        selectedID = roster.selectedID
    }

    func select(_ id: TerminalSession.ID) {
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
            // Shell exit keeps the window alive with a fresh tab.
            newTab()
        case .dismissWindow:
            closeWindowHandler(windowToClose)
        case .remaining, .notFound:
            break
        }
    }

    func selectNext() {
        roster.selectNext()
        selectedID = roster.selectedID
    }

    func selectPrevious() {
        roster.selectPrevious()
        selectedID = roster.selectedID
    }

    func refreshAppearance() {
        for session in sessions {
            session.applyAppearance()
        }
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
