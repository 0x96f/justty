//
//  FontWeightSettingTests.swift
//  justtyTests
//

import Testing
@testable import Justty

struct FontWeightSettingTests {
    @Test func fontStyleNames() {
        #expect(FontWeightSetting.regular.fontStyle == "Regular")
        #expect(FontWeightSetting.medium.fontStyle == "Medium")
        #expect(FontWeightSetting.semibold.fontStyle == "Semibold")
        #expect(FontWeightSetting.bold.fontStyle == "Bold")
    }

    @Test func variationWeights() {
        #expect(FontWeightSetting.regular.variationWeight == 400)
        #expect(FontWeightSetting.medium.variationWeight == 500)
        #expect(FontWeightSetting.semibold.variationWeight == 600)
        #expect(FontWeightSetting.bold.variationWeight == 700)
    }
}
