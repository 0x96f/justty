//
//  TerminalFont.swift
//  justty
//

import AppKit

enum TerminalFont {
    static let defaultSize: CGFloat = 13

    /// Concrete family name for Ghostty when the user has not overridden the font.
    /// Prefers the macOS system monospaced face; private `.`-prefixed names are
    /// mapped to SF Mono (or Menlo) so third-party loaders can resolve them.
    static var resolvedDefaultFamily: String {
        let font = NSFont.monospacedSystemFont(ofSize: defaultSize, weight: .regular)
        if let family = font.familyName, !family.hasPrefix(".") {
            return family
        }
        if NSFontManager.shared.availableFontFamilies.contains("SF Mono")
            || NSFont(name: "SFMono-Regular", size: defaultSize) != nil
        {
            return "SF Mono"
        }
        return "Menlo"
    }

    /// All non-hidden monospace families for the font picker, sorted A–Z.
    /// Includes fonts that omit the fixed-pitch flag (common for coding OTFs)
    /// when their ASCII advances are equal.
    static func selectableFamilies() -> [String] {
        NSFontManager.shared.availableFontFamilies
            .filter { family in
                guard !family.hasPrefix("."),
                      let font = representativeFont(inFamily: family)
                else { return false }
                return isMonospace(font)
            }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private static func representativeFont(inFamily family: String) -> NSFont? {
        if let font = NSFontManager.shared.font(
            withFamily: family, traits: [], weight: 5, size: defaultSize
        ) {
            return font
        }
        guard let name = NSFontManager.shared.availableMembers(ofFontFamily: family)?
            .first?[0] as? String
        else { return nil }
        return NSFont(name: name, size: defaultSize)
    }

    private static func isMonospace(_ font: NSFont) -> Bool {
        if font.isFixedPitch { return true }
        if font.fontDescriptor.symbolicTraits.contains(.monoSpace) { return true }
        return hasEqualASCIIAdvances(font)
    }

    /// Detects coding fonts that are monospaced but do not set OS/2 or CT flags.
    private static func hasEqualASCIIAdvances(_ font: NSFont) -> Bool {
        let sample = "il1|WMwm0O@# "
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        var width: CGFloat?
        for character in sample {
            let advance = (String(character) as NSString).size(withAttributes: attrs).width
            if let width {
                if abs(advance - width) > 0.01 { return false }
            } else {
                guard advance > 0 else { return false }
                width = advance
            }
        }
        return true
    }
}
