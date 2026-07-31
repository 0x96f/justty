//
//  JusttyConstants.swift
//  justty
//

import CoreGraphics

enum JusttyConstants {
    /// Fallback surface size before layout has a real frame.
    static let defaultTerminalWidth: CGFloat = 800
    static let defaultTerminalHeight: CGFloat = 600

    static let tabBarHeight: CGFloat = 36
    /// Cap each tab chip so long titles truncate instead of growing unboundedly.
    static let maxTabWidth: CGFloat = 250
    /// Space reserved for traffic lights when the title bar is hidden.
    static let trafficLightsLeadingInset: CGFloat = 78

    static let scrollbackLimit = "4194304"
}
