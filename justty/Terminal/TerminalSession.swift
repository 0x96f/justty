//
//  TerminalSession.swift
//  justty
//

import AppKit
import Combine
import Darwin
import Foundation
import GhosttyTerminal

/// One login shell rendered by one long-lived libghostty surface.
@MainActor
final class TerminalSession: NSObject, ObservableObject, Identifiable {
    let id = UUID()

    @Published var title: String
    @Published var hasExited = false

    let terminalView: AppTerminalView

    private let controller: TerminalController
    private let launchCommand: String
    private let shellName: String
    /// PTY foreground pid while idle at the shell prompt; used to detect a
    /// running foreground command without shell integration.
    private var shellPid: pid_t?
    private var isTerminating = false
    var onExited: ((TerminalSession) -> Void)?

    /// True when the PTY foreground process is not the login shell.
    var hasRunningCommand: Bool {
        guard let foreground = terminalView.foregroundPid else { return false }
        let name = Self.processName(for: foreground)

        // Idle when the foreground process is our login shell (also locks in shellPid).
        if name == shellName {
            shellPid = foreground
            return false
        }

        if let shellPid {
            return foreground != shellPid
        }

        // Shell not observed yet: treat a non-shell foreground as busy, but
        // ignore the brief `/bin/sh` wrapper used to exec the login shell.
        return name != nil && name != "sh"
    }

    override init() {
        let shellPath = JusttyTerminalConfig.loginShell()
        let launchCommand = JusttyTerminalConfig.makeLaunchCommand(shellPath: shellPath)
        let shellName = (shellPath as NSString).lastPathComponent

        self.launchCommand = launchCommand
        self.shellName = shellName
        title = shellName
        controller = TerminalController(
            configSource: .none,
            theme: JusttyTerminalConfig.ghosttyTheme(),
            terminalConfiguration: JusttyTerminalConfig.terminalConfiguration(
                command: launchCommand
            )
        )
        let terminalView = AppTerminalView(
            frame: NSRect(
                x: 0,
                y: 0,
                width: JusttyConstants.defaultTerminalWidth,
                height: JusttyConstants.defaultTerminalHeight
            )
        )
        self.terminalView = terminalView
        super.init()

        terminalView.delegate = self
        terminalView.configuration = TerminalSurfaceOptions(
            backend: .exec,
            workingDirectory: NSHomeDirectory(),
            envVars: JusttyTerminalConfig.surfaceEnvironment()
        )
        terminalView.controller = controller
        applyAppearance()
    }

    /// Reconfigures libghostty when theme or font settings change.
    func applyAppearance() {
        _ = controller.setTerminalConfiguration(
            JusttyTerminalConfig.terminalConfiguration(command: launchCommand)
        )
        _ = controller.setTheme(JusttyTerminalConfig.ghosttyTheme())
        controller.setColorScheme(Theme.isDark ? .dark : .light)
    }

    /// Tears down the surface when the host is already closing the tab.
    /// Does not invoke `onExited` - that callback is only for spontaneous
    /// shell/surface exit, otherwise TabManager.close would re-enter and
    /// remove with a stale index.
    func terminate() {
        guard !hasExited, !isTerminating else { return }
        isTerminating = true
        hasExited = true
        terminalView.controller = nil
    }

    private static func processName(for pid: pid_t) -> String? {
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        let length = buffer.withUnsafeMutableBufferPointer { ptr in
            proc_name(pid, ptr.baseAddress, UInt32(ptr.count))
        }
        guard length > 0 else { return nil }
        return String(cString: buffer)
    }
}

// MARK: - libghostty surface callbacks

extension TerminalSession: TerminalSurfaceTitleDelegate {
    func terminalDidChangeTitle(_ title: String) {
        guard !title.isEmpty else { return }
        self.title = title
    }
}

extension TerminalSession: TerminalSurfaceCloseDelegate {
    func terminalDidClose(processAlive _: Bool) {
        guard !isTerminating else { return }
        isTerminating = true
        hasExited = true
        onExited?(self)
    }
}

extension TerminalSession: TerminalSurfaceBellDelegate {
    func terminalDidRingBell() {
        NSSound.beep()
        if !NSApp.isActive {
            NSApp.requestUserAttention(.informationalRequest)
        }
    }
}

extension TerminalSession: TerminalSurfaceOpenURLDelegate {
    func terminalDidRequestOpenURL(_ url: String, kind _: TerminalOpenURLKind) {
        guard let target = URL(string: url) else { return }
        NSWorkspace.shared.open(target)
    }
}
