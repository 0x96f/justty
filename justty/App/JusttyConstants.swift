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
    /// Default width of the left tab rail when vertical tabs are enabled.
    static let verticalTabBarWidth: CGFloat = 180
    static let verticalTabBarMinWidth: CGFloat = 120
    static let verticalTabBarMaxWidth: CGFloat = 360
    /// Cap each tab chip so long titles truncate instead of growing unboundedly.
    static let maxTabWidth: CGFloat = 250
    /// Space reserved for traffic lights when the title bar is hidden.
    static let trafficLightsLeadingInset: CGFloat = 78

    static let scrollbackLimit = "4194304"
}
