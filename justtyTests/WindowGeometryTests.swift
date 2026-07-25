//
//  WindowGeometryTests.swift
//  justtyTests
//

import CoreGraphics
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
}
