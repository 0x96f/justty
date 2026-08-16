//
//  SidebarResizeHandle.swift
//  justty
//

import AppKit
import SwiftUI

/// AppKit drag handle so resize uses window coordinates (SwiftUI DragGesture on a
/// moving view jitters) and never animates width through invalid geometry.
struct SidebarResizeHandle: NSViewRepresentable {
    var width: Binding<CGFloat>
    var onDragBegan: () -> Void
    var onDragEnded: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(width: width, onDragBegan: onDragBegan, onDragEnded: onDragEnded)
    }

    func makeNSView(context: Context) -> NSView {
        let view = SidebarResizeHandleNSView()
        context.coordinator.bind(to: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? SidebarResizeHandleNSView else { return }
        context.coordinator.width = width
        context.coordinator.onDragBegan = onDragBegan
        context.coordinator.onDragEnded = onDragEnded
        context.coordinator.bind(to: view)
    }

    final class Coordinator {
        var width: Binding<CGFloat>
        var onDragBegan: () -> Void
        var onDragEnded: () -> Void

        init(
            width: Binding<CGFloat>,
            onDragBegan: @escaping () -> Void,
            onDragEnded: @escaping () -> Void
        ) {
            self.width = width
            self.onDragBegan = onDragBegan
            self.onDragEnded = onDragEnded
        }

        fileprivate func bind(to view: SidebarResizeHandleNSView) {
            view.currentWidth = { [weak self] in
                self?.width.wrappedValue ?? JusttyConstants.verticalTabBarWidth
            }
            view.onWidthChange = { [weak self] newWidth in
                guard let self else { return }
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    self.width.wrappedValue = newWidth
                }
            }
            view.onDragBegan = { [weak self] in self?.onDragBegan() }
            view.onDragEnded = { [weak self] in self?.onDragEnded() }
        }
    }
}

fileprivate final class SidebarResizeHandleNSView: NSView {
    var onWidthChange: ((CGFloat) -> Void)?
    var onDragBegan: (() -> Void)?
    var onDragEnded: (() -> Void)?
    var currentWidth: () -> CGFloat = { JusttyConstants.verticalTabBarWidth }

    private var dragStartWidth: CGFloat = 0
    private var dragStartX: CGFloat = 0
    private var isDragging = false

    override var mouseDownCanMoveWindow: Bool { false }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .resizeLeftRight)
    }

    override func mouseDown(with event: NSEvent) {
        isDragging = true
        dragStartWidth = currentWidth()
        dragStartX = event.locationInWindow.x
        NSCursor.resizeLeftRight.set()
        onDragBegan?()
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        let delta = event.locationInWindow.x - dragStartX
        let next = min(
            max(dragStartWidth + delta, JusttyConstants.verticalTabBarMinWidth),
            JusttyConstants.verticalTabBarMaxWidth
        )
        onWidthChange?(next)
    }

    override func mouseUp(with event: NSEvent) {
        guard isDragging else { return }
        isDragging = false
        onDragEnded?()
        window?.invalidateCursorRects(for: self)
    }
}
