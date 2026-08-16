//
//  WindowGeometryTests.swift
//  justtyTests
//

import CoreGraphics
import Foundation
import Testing
@testable import Justty

@MainActor
struct WindowGeometryTests {
    private let visible = CGRect(x: 100, y: 50, width: 1200, height: 800)
    private let frameSize = CGSize(width: 400, height: 300)

    @Test func convertsTopLeftOriginToCocoaBottomLeft() {
        let origin = WindowGeometry.frameOrigin(
            visibleFrame: visible,
            originX: 20,
            originY: 40,
            frameSize: frameSize
        )
        #expect(origin.x == 120)
        // visible.minY + visible.height - originY - frameHeight
        // 50 + 800 - 40 - 300 = 510
        #expect(origin.y == 510)
    }

    @Test func clampsOriginInsideVisibleFrame() {
        let origin = WindowGeometry.frameOrigin(
            visibleFrame: visible,
            originX: 10_000,
            originY: 10_000,
            frameSize: frameSize
        )
        #expect(origin.x == visible.maxX - frameSize.width)
        #expect(origin.y == visible.minY)
    }

    @Test func clampsNegativeOffsetsToVisibleOrigin() {
        let origin = WindowGeometry.frameOrigin(
            visibleFrame: visible,
            originX: 0,
            originY: 0,
            frameSize: frameSize
        )
        #expect(origin.x == visible.minX)
        #expect(origin.y == visible.maxY - frameSize.height)
    }

    @Test func contentSizeAddsVerticalTabRailWidth() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("justty-geom-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let url = dir.appendingPathComponent("config.yml")
        let settings = AppSettings(configURL: url, persistDebounce: .zero)
        let horizontal = WindowGeometry.contentSize(from: settings)
        settings.verticalTabs = true
        settings.verticalTabBarWidth = Int(JusttyConstants.verticalTabBarWidth)
        let vertical = WindowGeometry.contentSize(from: settings)

        #expect(
            vertical.width == horizontal.width + CGFloat(settings.verticalTabBarWidth)
        )
        #expect(vertical.height == horizontal.height)

        settings.verticalTabBarWidth = 240
        let wider = WindowGeometry.contentSize(from: settings)
        #expect(wider.width == horizontal.width + 240)
    }
}
