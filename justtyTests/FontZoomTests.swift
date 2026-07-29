//
//  FontZoomTests.swift
//  justtyTests
//

import Testing
@testable import Justty

struct FontZoomTests {
    @Test func effectiveUsesBaseWhenOverrideNil() {
        #expect(FontZoom.effective(base: 13, override: nil) == 13)
    }

    @Test func effectiveUsesOverrideWhenPresent() {
        #expect(FontZoom.effective(base: 13, override: 16) == 16)
    }

    @Test func increasedClampsToUpperBound() {
        let max = AppSettings.Limits.fontSize.upperBound
        #expect(FontZoom.increased(base: max, override: nil) == max)
        #expect(FontZoom.increased(base: 13, override: max - 0.5) == max)
    }

    @Test func decreasedClampsToLowerBound() {
        let min = AppSettings.Limits.fontSize.lowerBound
        #expect(FontZoom.decreased(base: min, override: nil) == min)
        #expect(FontZoom.decreased(base: 13, override: min + 0.5) == min)
    }

    @Test func stepIsOnePoint() {
        #expect(FontZoom.increased(base: 13, override: nil) == 14)
        #expect(FontZoom.decreased(base: 13, override: nil) == 12)
    }

    @Test func clampRejectsOutOfRange() {
        #expect(FontZoom.clamp(1) == AppSettings.Limits.fontSize.lowerBound)
        #expect(FontZoom.clamp(100) == AppSettings.Limits.fontSize.upperBound)
    }
}
