//
//  CropGeometryTests.swift
//  vynlTests
//
//  COV-3 (SCRUM-59): the square under the frame, in image pixels, for any
//  zoom and drag, and the photo never leaves the square uncovered.
//

import CoreGraphics
import Testing
@testable import vynl

struct CropGeometryTests {

    // A 4:3 landscape photo, 4000×3000 px, under a 300 pt frame.
    private let g = CropGeometry(imageSize: CGSize(width: 4000, height: 3000), frameSide: 300)

    @Test func atRestItIsTheLargestCentredSquare() {
        let r = g.cropRect(zoom: 1, offset: .zero)
        #expect(r == CGRect(x: 500, y: 0, width: 3000, height: 3000))
    }

    @Test func zoomingInShrinksTheSquareAroundTheCentre() {
        let r = g.cropRect(zoom: 2, offset: .zero)
        #expect(r == CGRect(x: 1250, y: 750, width: 1500, height: 1500))
    }

    @Test func draggingTheImageRightMovesTheCropLeft() {
        // At zoom 1: 0.1 pt per px. 30 pt to the right = 300 px left.
        let r = g.cropRect(zoom: 1, offset: CGSize(width: 30, height: 0))
        #expect(r.origin.x == 200)
        #expect(r.origin.y == 0)
    }

    @Test func theImageCannotBeDraggedOffTheSquare() {
        // At zoom 1 the image can move 50 pt sideways and not at all vertically.
        #expect(g.maxOffset(zoom: 1) == CGSize(width: 50, height: 0))
        let r = g.cropRect(zoom: 1, offset: CGSize(width: 500, height: -500))
        #expect(r == CGRect(x: 0, y: 0, width: 3000, height: 3000))
    }

    @Test func aPortraitPhotoWorksTheSame() {
        let portrait = CropGeometry(imageSize: CGSize(width: 3000, height: 4000), frameSide: 300)
        #expect(portrait.cropRect(zoom: 1, offset: .zero) == CGRect(x: 0, y: 500, width: 3000, height: 3000))
    }
}
