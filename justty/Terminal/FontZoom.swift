//
//  FontZoom.swift
//  justty
//

import Foundation

/// Per-tab temporary font size override; cleared when Settings refresh.
/// Never writes config.yml.
enum FontZoom {
    static let step = 1.0

    static func clamp(_ size: Double) -> Double {
        min(max(size, AppSettings.Limits.fontSize.lowerBound), AppSettings.Limits.fontSize.upperBound)
    }

    static func effective(base: Double, override: Double?) -> Double {
        clamp(override ?? base)
    }

    static func increased(base: Double, override: Double?) -> Double {
        clamp(effective(base: base, override: override) + step)
    }

    static func decreased(base: Double, override: Double?) -> Double {
        clamp(effective(base: base, override: override) - step)
    }
}
