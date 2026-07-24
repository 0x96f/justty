//
//  TerminalHostView.swift
//  justty
//

import AppKit
import SwiftUI

/// Hosts a session's long-lived Ghostty terminal view in SwiftUI.
struct TerminalHostView: NSViewRepresentable {
    let session: TerminalSession
    var isFocused: Bool = true

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> TerminalContainerView {
        let container = TerminalContainerView()
        container.terminal = session.terminalView
        container.focusOnAppear = isFocused

        let terminal = session.terminalView
        terminal.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(terminal)
        NSLayoutConstraint.activate([
            terminal.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            terminal.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            terminal.topAnchor.constraint(equalTo: container.topAnchor),
            terminal.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        context.coordinator.isFocused = isFocused
        return container
    }

    func updateNSView(_ view: TerminalContainerView, context: Context) {
        view.focusOnAppear = isFocused
        if isFocused, !context.coordinator.isFocused {
            view.requestTerminalFocus()
        }
        context.coordinator.isFocused = isFocused
    }

    final class Coordinator {
        var isFocused = false
    }
}

/// Keeps non-visible terminals attached to the window so libghostty can keep
/// draining exec/process events for background tabs.
struct TerminalParkingView: NSViewRepresentable {
    let sessions: [TerminalSession]

    func makeNSView(context: Context) -> TerminalParkingContainerView {
        TerminalParkingContainerView(frame: .zero)
    }

    func updateNSView(_ view: TerminalParkingContainerView, context: Context) {
        view.mount(sessions)
    }

    static func dismantleNSView(
        _ view: TerminalParkingContainerView, coordinator: ()
    ) {
        view.unmountAll()
    }
}

final class TerminalParkingContainerView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
        alphaValue = 0
        setAccessibilityElement(false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func mount(_ sessions: [TerminalSession]) {
        let desired = Set(sessions.map { ObjectIdentifier($0.terminalView) })
        for subview in subviews where !desired.contains(ObjectIdentifier(subview)) {
            subview.removeFromSuperview()
        }

        for session in sessions {
            let terminal = session.terminalView
            guard terminal.superview !== self else { continue }
            let parkedSize = terminal.frame.size
            if terminal.window?.firstResponder === terminal {
                terminal.window?.makeFirstResponder(nil)
            }
            terminal.removeFromSuperview()
            terminal.translatesAutoresizingMaskIntoConstraints = true
            let hasUsableSize =
                parkedSize.width.isFinite && parkedSize.height.isFinite
                && parkedSize.width > 0 && parkedSize.height > 0
            terminal.frame = NSRect(
                origin: .zero,
                size: hasUsableSize
                    ? parkedSize
                    : NSSize(
                        width: JusttyConstants.defaultTerminalWidth,
                        height: JusttyConstants.defaultTerminalHeight
                    )
            )
            addSubview(terminal)
        }
    }

    func unmountAll() {
        for subview in subviews { subview.removeFromSuperview() }
    }
}

final class TerminalContainerView: NSView {
    weak var terminal: NSView?
    var focusOnAppear = true {
        didSet {
            if !focusOnAppear { pendingFocusRequest = false }
        }
    }
    private var pendingFocusRequest = false

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil, focusOnAppear {
            requestTerminalFocus()
        }
    }

    func requestTerminalFocus() {
        guard focusOnAppear else { return }
        if let window, window.isKeyWindow, let terminal {
            window.makeFirstResponder(terminal)
            pendingFocusRequest = false
        } else {
            pendingFocusRequest = true
        }
    }

    @objc private func windowDidBecomeKey(_ notification: Notification) {
        guard pendingFocusRequest,
              let window,
              notification.object as? NSWindow === window,
              let terminal
        else { return }
        window.makeFirstResponder(terminal)
        pendingFocusRequest = false
    }
}
