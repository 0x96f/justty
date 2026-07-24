//
//  FontWeightSetting.swift
//  justty
//

enum FontWeightSetting: String, CaseIterable, Identifiable {
    case regular
    case medium
    case semibold
    case bold

    var id: String { rawValue }

    /// Display name and Ghostty `font-style` face name for static fonts.
    var fontStyle: String {
        switch self {
        case .regular: return "Regular"
        case .medium: return "Medium"
        case .semibold: return "Semibold"
        case .bold: return "Bold"
        }
    }

    /// Variable-font weight axis value.
    var variationWeight: Int {
        switch self {
        case .regular: return 400
        case .medium: return 500
        case .semibold: return 600
        case .bold: return 700
        }
    }
}
