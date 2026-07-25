//
//  WindowGeometry.swift
//  justty
//

import AppKit

/// Estimates window content size from character grid settings and converts
/// top-left screen origins into Cocoa window frames.
@MainActor
enum WindowGeometry {
    /// Point size for a new window's content area (tab bar + padded terminal).
    static func contentSize(from settings: AppSettings? = nil) -> CGSize {
        // Resolve .shared in the @MainActor body — default args are nonisolated.
        let settings = settings ?? .shared
        let cell = estimatedCellSize(from: settings)
        let padding = CGFloat(settings.terminalPadding) * 2
        let width = CGFloat(settings.windowColumns) * cell.width + padding
        let height = JusttyConstants.tabBarHeight
            + CGFloat(settings.windowRows) * cell.height
            + padding
        return CGSize(width: max(width, 200), height: max(height, 120))
    }

    /// Applies starting size and position once per window.
    /// User origin is top-left of the visible desktop (below menu bar);
    /// Cocoa origin is bottom-left.
    static func applyInitialFrame(to window: NSWindow, settings: AppSettings? = nil) {
        let settings = settings ?? .shared
        let size = contentSize(from: settings)
        window.setContentSize(size)

        let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first
        guard let screen else { return }

        // Use visibleFrame so X/Y share the same usable origin. Measuring from
        // screen.frame made Y include the menu bar while X did not.
        let origin = frameOrigin(
            visibleFrame: screen.visibleFrame,
            originX: settings.windowOriginX,
            originY: settings.windowOriginY,
            frameSize: window.frame.size
        )
        window.setFrameOrigin(origin)
    }

    /// Converts top-left desktop offsets into a Cocoa bottom-left origin and
    /// clamps so the window stays inside the usable screen area.
    static func frameOrigin(
        visibleFrame: CGRect,
        originX: Int,
        originY: Int,
        frameSize: CGSize
    ) -> CGPoint {
        var origin = CGPoint(
            x: visibleFrame.origin.x + CGFloat(originX),
            y: visibleFrame.origin.y
                + visibleFrame.height
                - CGFloat(originY)
                - frameSize.height
        )
        origin.x = min(
            max(origin.x, visibleFrame.minX),
            visibleFrame.maxX - frameSize.width
        )
        origin.y = min(
            max(origin.y, visibleFrame.minY),
            visibleFrame.maxY - frameSize.height
        )
        return origin
    }

    private static func estimatedCellSize(from settings: AppSettings) -> CGSize {
        let font = resolvedFont(from: settings)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let advance = ("M" as NSString).size(withAttributes: attrs).width
        let lineHeight = ceil(font.ascender - font.descender + font.leading)
            * settings.lineHeight
        return CGSize(
            width: max(advance, 1),
            height: max(lineHeight, 1)
        )
    }

    private static func resolvedFont(from settings: AppSettings) -> NSFont {
        let size = CGFloat(settings.fontSize)
        let weight = settings.fontWeight.nsFontWeight
        let family = settings.fontFamily.isEmpty
            ? TerminalFont.resolvedDefaultFamily
            : settings.fontFamily

        if let font = NSFontManager.shared.font(
            withFamily: family,
            traits: [],
            weight: settings.fontWeight.nsFontManagerWeight,
            size: size
        ) {
            return font
        }
        if let font = NSFont(name: family, size: size) {
            return font
        }
        return NSFont.monospacedSystemFont(ofSize: size, weight: weight)
    }
}

private extension FontWeightSetting {
    var nsFontWeight: NSFont.Weight {
        switch self {
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }

    /// `NSFontManager` weight scale (0…15); 5 is Regular.
    var nsFontManagerWeight: Int {
        switch self {
        case .regular: return 5
        case .medium: return 6
        case .semibold: return 8
        case .bold: return 9
        }
    }
}
