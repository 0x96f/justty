//
//  WindowChrome.swift
//  justty
//

import AppKit
import ObjectiveC
import SwiftUI

/// Transparent region that lets mouse-downs drag the window (needed with a hidden title bar).
struct WindowDragRegion: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        WindowDragNSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private final class WindowDragNSView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            window?.zoom(nil)
            return
        }
        // Single-click drag is handled by mouseDownCanMoveWindow.
    }
}

/// Ensures content draws under the traffic-light area with a transparent titlebar,
/// and applies starting size/position once when the window first appears.
struct WindowChromeConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            Self.configure(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            Self.configure(nsView.window)
        }
    }

    private static func configure(_ window: NSWindow?) {
        guard let window else { return }
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.toolbar = nil

        // One-shot: starting geometry from settings applies only to new windows.
        if window.justtyDidApplyInitialGeometry { return }
        window.justtyDidApplyInitialGeometry = true
        WindowGeometry.applyInitialFrame(to: window)
    }
}

private extension NSWindow {
    private static var initialGeometryKey: UInt8 = 0

    var justtyDidApplyInitialGeometry: Bool {
        get {
            (objc_getAssociatedObject(self, &Self.initialGeometryKey) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(
                self,
                &Self.initialGeometryKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}
