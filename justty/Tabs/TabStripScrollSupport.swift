//
//  TabStripScrollSupport.swift
//  justty
//

import SwiftUI

/// Mutable scroll metrics read by arrow actions without publishing every frame.
final class TabStripMetrics {
    var offset: CGFloat = 0
    var contentLength: CGFloat = 0
    var viewportLength: CGFloat = 0
}

struct TabStripScrollFlags: Equatable {
    var overflows: Bool
    var canScrollBackward: Bool
    var canScrollForward: Bool
    var contentLength: CGFloat
}

enum TabStripScroll {
    /// Page jump target along the scroll axis (x for horizontal, y for vertical).
    static func pageTarget(direction: CGFloat, metrics: TabStripMetrics) -> CGFloat {
        let page = max(metrics.viewportLength * 0.75, 80)
        let maxOffset = max(0, metrics.contentLength - metrics.viewportLength)
        return min(max(0, metrics.offset + direction * page), maxOffset)
    }

    static func flags(
        offset: CGFloat,
        contentLength: CGFloat,
        viewportLength: CGFloat
    ) -> TabStripScrollFlags {
        let overflows = contentLength > viewportLength + 0.5
        return TabStripScrollFlags(
            overflows: overflows,
            canScrollBackward: overflows && offset > 0.5,
            canScrollForward: overflows && offset < contentLength - viewportLength - 0.5,
            contentLength: contentLength
        )
    }
}

struct TabStripScrollButton: View {
    let systemName: String
    let help: String
    let enabled: Bool
    /// Vertical rail chevrons span the strip width; horizontal ones stay compact.
    var expandsHorizontally: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .semibold))
                .modifier(TabStripScrollButtonFrame(expandsHorizontally: expandsHorizontally))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 0.85 : 0.35)
        .help(help)
    }
}

private struct TabStripScrollButtonFrame: ViewModifier {
    let expandsHorizontally: Bool

    func body(content: Content) -> some View {
        if expandsHorizontally {
            content
                .frame(maxWidth: .infinity)
                .frame(height: 24)
        } else {
            content
                .frame(width: 28, height: 24)
        }
    }
}
