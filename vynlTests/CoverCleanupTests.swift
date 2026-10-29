//
//  CoverCleanupTests.swift
//  vynlTests
//
//  COV-4 (SCRUM-61): the cleanup on drawn photos. A record on a table gets its
//  label found, a skewed sleeve gets found and straightened to a square, a
//  flat photo finds nothing and is left as is.
//

import Testing
import UIKit
@testable import vynl

struct CoverCleanupTests {

    private func draw(_ size: CGSize, _ body: (CGContext) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { body($0.cgContext) }
    }

    /// A black record (r 500) on a grey table, an orange label (r 165) a bit
    /// off centre.
    private func record() -> UIImage {
        draw(CGSize(width: 1200, height: 1200)) { c in
            UIColor(white: 0.75, alpha: 1).setFill()
            c.fill(CGRect(x: 0, y: 0, width: 1200, height: 1200))
            UIColor(white: 0.05, alpha: 1).setFill()
            c.fillEllipse(in: CGRect(x: 120, y: 80, width: 1000, height: 1000))
            UIColor(red: 0.95, green: 0.55, blue: 0.1, alpha: 1).setFill()
            c.fillEllipse(in: CGRect(x: 620 - 165, y: 580 - 165, width: 330, height: 330))
        }
    }

    @Test func findsTheLabelOnARecord() throws {
        let label = try #require(CoverCleanup.detectLabel(record()))
        #expect(abs(label.center.x - 620) < 20)
        #expect(abs(label.center.y - 580) < 20)
        #expect(abs(label.radius - 165) < 20)
    }

    @Test func theSquareAroundTheLabelFitsItInTheCircle() {
        let label = CoverCleanup.Circle(center: CGPoint(x: 600, y: 600), radius: 165)
        let square = CoverCleanup.square(around: label, in: CGSize(width: 1200, height: 1200))
        #expect(abs(square.width - 330 / CoverArt.labelRatio) < 0.5)
        #expect(abs(square.midX - 600) < 0.5)
        #expect(abs(square.midY - 600) < 0.5)
    }

    @Test func theSquareStaysInsideThePhoto() {
        let label = CoverCleanup.Circle(center: CGPoint(x: 100, y: 1150), radius: 165)
        let square = CoverCleanup.square(around: label, in: CGSize(width: 1200, height: 1200))
        #expect(square.minX >= 0)
        #expect(square.maxY <= 1200.5)
    }

    /// A white sleeve seen at an angle on a dark table.
    private func skewedSleeve() -> UIImage {
        draw(CGSize(width: 1200, height: 1000)) { c in
            UIColor(white: 0.1, alpha: 1).setFill()
            c.fill(CGRect(x: 0, y: 0, width: 1200, height: 1000))
            UIColor(white: 0.95, alpha: 1).setFill()
            c.move(to: CGPoint(x: 260, y: 140))
            c.addLine(to: CGPoint(x: 960, y: 180))
            c.addLine(to: CGPoint(x: 1000, y: 880))
            c.addLine(to: CGPoint(x: 220, y: 860))
            c.closePath()
            c.fillPath()
        }
    }

    @Test func findsAndStraightensASkewedSleeve() throws {
        let image = skewedSleeve()
        let quad = try #require(CoverCleanup.detectSleeve(image))
        #expect(CoverCleanup.detectShape(image) == .sleeve(quad))
        let straight = try #require(CoverCleanup.straightened(image, quad: quad))
        let cg = try #require(straight.cgImage)
        #expect(cg.width == cg.height)
        // It's the sleeve now, not the table: the corners are light.
        let corner = try #require(UIImage(cgImage: cg.cropping(to: CGRect(x: 8, y: 8, width: 4, height: 4))!)
            .averageWhite)
        #expect(corner > 0.6)
    }

    /// A bare record shot at an angle: an ellipse 900×600, label 300×200.
    private func tiltedRecord() -> UIImage {
        draw(CGSize(width: 1200, height: 1000)) { c in
            UIColor(white: 0.75, alpha: 1).setFill()
            c.fill(CGRect(x: 0, y: 0, width: 1200, height: 1000))
            UIColor(white: 0.05, alpha: 1).setFill()
            c.fillEllipse(in: CGRect(x: 150, y: 200, width: 900, height: 600))
            UIColor(red: 0.95, green: 0.55, blue: 0.1, alpha: 1).setFill()
            c.fillEllipse(in: CGRect(x: 450, y: 400, width: 300, height: 200))
        }
    }

    @Test func aTiltedRecordIsFoundAndMadeRound() throws {
        let image = tiltedRecord()
        guard case .record(let e)? = CoverCleanup.detectShape(image) else {
            Issue.record("no record found"); return
        }
        #expect(abs(e.a - 450) < 25)
        #expect(abs(e.b - 300) < 25)
        let round = try #require(CoverCleanup.straightened(image, record: e))
        #expect(round.cgImage?.width == round.cgImage?.height)
        // The label is a circle now, so the label finder takes it.
        let label = try #require(CoverCleanup.detectLabel(round))
        #expect(abs(label.radius - 150) < 20)
    }

    @Test func aFlatPhotoFindsNothingAndIsLeftAlone() {
        let flat = draw(CGSize(width: 800, height: 600)) { c in
            UIColor(red: 0.3, green: 0.4, blue: 0.5, alpha: 1).setFill()
            c.fill(CGRect(x: 0, y: 0, width: 800, height: 600))
        }
        #expect(CoverCleanup.detectShape(flat) == nil)
        #expect(CoverCleanup.detectLabel(flat) == nil)
        let out = CoverCleanup.process(flat, shape: nil, options: .init(straighten: true, enhance: false))
        #expect(out === flat)
    }

    @Test func enhanceKeepsTheSize() throws {
        let image = record()
        let out = try #require(CoverCleanup.enhanced(image))
        #expect(out.cgImage?.width == 1200)
        #expect(out.cgImage?.height == 1200)
    }

    @Test func runPlacesTheSquareOnTheLabel() throws {
        let result = CoverCleanup.run(record(), shape: nil, options: .init(straighten: false, enhance: false))
        let square = try #require(result.labelSquare)
        #expect(abs(square.midX - 620) < 25)
        #expect(abs(square.midY - 580) < 25)
    }
}

private extension UIImage {
    /// Mean brightness 0…1, drawn into a 1×1 grey pixel.
    var averageWhite: CGFloat? {
        guard let cg = cgImage else { return nil }
        var pixel: UInt8 = 0
        guard let ctx = CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 1,
                                  space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
        else { return nil }
        ctx.interpolationQuality = .medium
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return CGFloat(pixel) / 255
    }
}
