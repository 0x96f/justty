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
    @Published var selectedID: TerminalSession.ID?

    var selectedSession: TerminalSession? {
        sessions.first { $0.id == selectedID }
    }

    var parkedSessions: [TerminalSession] {
        sessions.filter { $0.id != selectedID }
    }

    private var cancellables = Set<AnyCancellable>()

    init() {
        newTab()
        NotificationCenter.default.publisher(for: .justtySettingsDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshAppearance() }
            .store(in: &cancellables)
    }

    func newTab() {
        let session = TerminalSession()
        session.onExited = { [weak self] exited in
            self?.close(exited, fromShellExit: true)
        }
        sessions.append(session)
        selectedID = session.id
    }

    func select(_ id: TerminalSession.ID) {
        guard sessions.contains(where: { $0.id == id }) else { return }
        selectedID = id
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
            confirmClose(session)
            return
        }

        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else {
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
        sessions.remove(at: index)
        if !fromShellExit, !session.hasExited {
            session.terminate()
        }
        if sessions.isEmpty {
            // Shell exit keeps the window alive with a fresh tab; user close
            // of the last tab dismisses the window instead.
            if fromShellExit {
                newTab()
            } else {
                DispatchQueue.main.async {
                    windowToClose?.close()
                }
            }
            return
        }
        if selectedID == session.id {
            let nextIndex = min(index, sessions.count - 1)
            selectedID = sessions[nextIndex].id
        }
    }

    private func confirmClose(_ session: TerminalSession) {
        let alert = NSAlert()
        alert.messageText = "Close this tab?"
        alert.informativeText =
            "You have a running process in this tab. Closing it will terminate the process."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Close")
        alert.addButton(withTitle: "Cancel")

        let respond: (NSApplication.ModalResponse) -> Void = { [weak self] response in
            guard response == .alertFirstButtonReturn else { return }
            // Let the sheet finish dismissing before closing tab/window.
            DispatchQueue.main.async {
                self?.close(session, skipConfirm: true)
            }
        }

        if let window = session.terminalView.window ?? NSApp.keyWindow {
            alert.beginSheetModal(for: window, completionHandler: respond)
        } else {
            respond(alert.runModal())
        }
    }

    func selectNext() {
        guard let selectedID,
              let index = sessions.firstIndex(where: { $0.id == selectedID })
        else { return }
        let next = sessions[(index + 1) % sessions.count]
        self.selectedID = next.id
    }

    func selectPrevious() {
        guard let selectedID,
              let index = sessions.firstIndex(where: { $0.id == selectedID })
        else { return }
        let previous = sessions[(index - 1 + sessions.count) % sessions.count]
        self.selectedID = previous.id
    }

    func refreshAppearance() {
        for session in sessions {
            session.applyAppearance()
        }
    }
}
