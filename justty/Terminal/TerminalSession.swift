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
    /// Temporary per-tab size; nil means use Settings. Never persisted.
    private var fontSizeOverride: Double?
    /// Last OSC 7 path from the surface when the shell emits it.
    private var reportedWorkingDirectory: String?
    /// PTY foreground pid while idle at the shell prompt; used to detect a
    /// running foreground command without shell integration.
    private var shellPid: pid_t?
    private var isTerminating = false
    var onExited: ((TerminalSession) -> Void)?

    var effectiveFontSize: Double {
        FontZoom.effective(
            base: AppSettings.shared.fontSize,
            override: fontSizeOverride
        )
    }

    /// Directory for a sibling tab: OSC 7 if usable, else shell/foreground cwd, else home.
    var resolvedWorkingDirectory: String {
        refreshShellPid()
        return ProcessWorkingDirectory.resolve(
            reportedPath: reportedWorkingDirectory,
            shellPid: shellPid,
            foregroundPid: terminalView.foregroundPid
        )
    }

    /// True when the PTY foreground process is not the login shell.
    var hasRunningCommand: Bool {
        let foreground = terminalView.foregroundPid
        let name = foreground.flatMap(Self.processName(for:))
        let result = Self.hasRunningCommand(
            foregroundPid: foreground,
            foregroundName: name,
            shellName: shellName,
            shellPid: shellPid
        )
        if let locked = result.lockedShellPid {
            shellPid = locked
        }
        return result.isBusy
    }

    /// Pure busy policy for close-confirm without reading the live PTY.
    /// When the foreground is the login shell, `lockedShellPid` is that pid.
    static func hasRunningCommand(
        foregroundPid: pid_t?,
        foregroundName: String?,
        shellName: String,
        shellPid: pid_t?
    ) -> (isBusy: Bool, lockedShellPid: pid_t?) {
        guard let foregroundPid else {
            return (false, nil)
        }

        // Idle when the foreground process is our login shell (also locks in shellPid).
        if foregroundName == shellName {
            return (false, foregroundPid)
        }

        if let shellPid {
            return (foregroundPid != shellPid, nil)
        }

        // Shell not observed yet: treat a non-shell foreground as busy, but
        // ignore the brief `/bin/sh` wrapper used to exec the login shell.
        let isBusy = foregroundName != nil && foregroundName != "sh"
        return (isBusy, nil)
    }

    init(workingDirectory: String = NSHomeDirectory()) {
        let shellPath = JusttyTerminalConfig.loginShell()
        let launchCommand = JusttyTerminalConfig.makeLaunchCommand(shellPath: shellPath)
        let shellName = (shellPath as NSString).lastPathComponent
        let launchCwd = ProcessWorkingDirectory.isUsableDirectory(workingDirectory)
            ? workingDirectory
            : NSHomeDirectory()

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
            workingDirectory: launchCwd,
            envVars: JusttyTerminalConfig.surfaceEnvironment()
        )
        terminalView.controller = controller
        applyAppearance()
    }

    /// Reconfigures libghostty when theme or font settings change.
    /// Pass `clearFontZoom: true` on Settings refresh so tabs adopt the new
    /// Settings size instead of keeping a temporary ⌘+/− override.
    func applyAppearance(clearFontZoom: Bool = false) {
        if clearFontZoom {
            fontSizeOverride = nil
        }
        _ = controller.setTerminalConfiguration(
            JusttyTerminalConfig.terminalConfiguration(
                command: launchCommand,
                fontSize: effectiveFontSize
            )
        )
        _ = controller.setTheme(JusttyTerminalConfig.ghosttyTheme())
        controller.setColorScheme(Theme.isDark ? .dark : .light)
    }

    func increaseFontSize() {
        fontSizeOverride = FontZoom.increased(
            base: AppSettings.shared.fontSize,
            override: fontSizeOverride
        )
        applyAppearance()
    }

    func decreaseFontSize() {
        fontSizeOverride = FontZoom.decreased(
            base: AppSettings.shared.fontSize,
            override: fontSizeOverride
        )
        applyAppearance()
    }

    func resetFontSize() {
        guard fontSizeOverride != nil else { return }
        fontSizeOverride = nil
        applyAppearance()
    }

    func performFindSearch(_ query: String) {
        _ = terminalView.performBindingAction(TerminalFind.searchAction(for: query))
    }

    func performFindNext() {
        _ = terminalView.performBindingAction(TerminalFind.navigateNext)
    }

    func performFindPrevious() {
        _ = terminalView.performBindingAction(TerminalFind.navigatePrevious)
    }

    func endFindSearch() {
        _ = terminalView.performBindingAction(TerminalFind.end)
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

    private func refreshShellPid() {
        // hasRunningCommand locks shellPid when the foreground is the login shell.
        _ = hasRunningCommand
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

extension TerminalSession: TerminalSurfacePwdDelegate {
    func terminalDidChangeWorkingDirectory(_ path: String) {
        guard !path.isEmpty else { return }
        reportedWorkingDirectory = path
    }
}
