//
//  CoverArtTests.swift
//  vynlTests
//
//  DR-5 (SCRUM-34): coverColor, downscale, placeholder seed. Images are drawn
//  in code, so each expectation is exact.
//

import Testing
import UIKit
@testable import vynl

struct CoverArtTests {

    /// A size×size image: `base` everywhere, `accent` filling `share` of it as a
    /// horizontal band at the top.
    private func image(base: UIColor, accent: UIColor, share: Double, size: CGFloat = 320) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format).image { ctx in
            base.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
            accent.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: size, height: size * share))
        }
    }

    private func rgb(_ hex: String) -> (Int, Int, Int) {
        let v = Int(hex.dropFirst(), radix: 16)!
        return ((v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF)
    }

    /// A record photo as SCRUM-41 found it: grey table, big black disc, a small
    /// red label in the middle (~3% of the frame).
    private func recordPhoto(label: UIColor, background: UIColor = UIColor(white: 0.55, alpha: 1),
                             size: CGFloat = 600) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format).image { ctx in
            background.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
            UIColor(white: 0.04, alpha: 1).setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: size * 0.08, y: size * 0.08, width: size * 0.84, height: size * 0.84))
            label.setFill()
            let r = size * 0.1
            ctx.cgContext.fillEllipse(in: CGRect(x: size / 2 - r, y: size / 2 - r, width: 2 * r, height: 2 * r))
        }
    }

    @Test func aRecordPhotoTakesTheLabelNotTheBlackDisc() throws {
        let img = recordPhoto(label: UIColor(red: 0.85, green: 0.27, blue: 0.18, alpha: 1))
        let hex = CoverArt.hex(try #require(CoverArt.coverColor(of: img)))
        let (r, g, b) = rgb(hex)
        #expect(r > 180 && g < 110 && b < 100, "expected the red label, got \(hex)")
    }

    @Test func aRecordPhotoOnAWhiteTableStillTakesTheLabel() throws {
        let img = recordPhoto(label: UIColor(red: 0.09, green: 0.73, blue: 0.74, alpha: 1), background: .white)
        let hex = CoverArt.hex(try #require(CoverArt.coverColor(of: img)))
        let (r, g, b) = rgb(hex)
        #expect(r < 90 && g > 140 && b > 140, "expected the teal label, got \(hex)")
    }

    @Test func neverBlackOrWhite() throws {
        // Black-and-white sleeve: no colour at all → nil (the label falls back to a key colour).
        let img = image(base: UIColor(white: 0.05, alpha: 1), accent: .white, share: 0.4)
        #expect(CoverArt.coverColor(of: img) == nil)
    }

    @Test func aMutedSleeveFallsBackToTheContrastRule() throws {
        // Dark grey sleeve with a mid-grey band: nothing vivid, the band contrasts.
        let img = image(base: UIColor(white: 0.18, alpha: 1), accent: UIColor(white: 0.6, alpha: 1), share: 0.3)
        let hex = CoverArt.hex(try #require(CoverArt.coverColor(of: img)))
        let (r, _, _) = rgb(hex)
        #expect(r > 130, "expected the light-grey band, got \(hex)")
    }

    @Test func aStrongColourBeatsABiggerDullOne() throws {
        // Dark teal sleeve (vivid, 80%) with a cream band (dull, 20%): teal, the colour of the sleeve.
        let img = image(base: UIColor(red: 0.11, green: 0.31, blue: 0.35, alpha: 1),
                        accent: UIColor(red: 0.93, green: 0.89, blue: 0.81, alpha: 1), share: 0.2)
        let hex = CoverArt.hex(try #require(CoverArt.coverColor(of: img)))
        let (r, g, b) = rgb(hex)
        #expect(r < 60 && g > 60 && b > 70, "expected teal, got \(hex)")
    }

    @Test func ignoresSpecks() throws {
        // A 0.5% red sliver on a dark sleeve is noise, not the label.
        let img = image(base: UIColor(white: 0.1, alpha: 1), accent: .red, share: 0.005)
        if let c = CoverArt.coverColor(of: img) {
            let (r, g, _) = rgb(CoverArt.hex(c))
            #expect(!(r > 200 && g < 60), "the speck won")
        }
    }

    @Test func aBigPhotoIsDownscaledOnSave() throws {
        let big = image(base: .darkGray, accent: .orange, share: 0.3, size: 3000)
        let png = try #require(big.pngData())
        let prepared = try #require(CoverArt.prepare(png))
        let stored = try #require(UIImage(data: prepared.cover))
        #expect(max(stored.size.width, stored.size.height) * stored.scale <= CoverArt.maxDimension)
        #expect(prepared.color != nil)
    }

    @Test func aSmallPhotoKeepsItsSize() throws {
        let small = image(base: .darkGray, accent: .orange, share: 0.3, size: 400)
        let png = try #require(small.pngData())
        let prepared = try #require(CoverArt.prepare(png))
        let stored = try #require(UIImage(data: prepared.cover))
        #expect(stored.size.width * stored.scale == 400)
    }

    @Test func theSeedIsStableAndDependsOnBothNames() {
        let a = CoverArt.seed(artist: "Surgeon", title: "Internal Empire")
        #expect(a == CoverArt.seed(artist: "Surgeon", title: "Internal Empire"))
        #expect(a != CoverArt.seed(artist: "Surgeon", title: "Basictonalvocabulary"))
        #expect(a != CoverArt.seed(artist: "Regis", title: "Internal Empire"))
    }

    @Test func placeholderLabelIsAKeyColourFromTheSeed() {
        #expect(CoverArt.placeholderLabelKey(seed: 0) == .k1A)
        #expect(CoverArt.placeholderLabelKey(seed: 15 << 4) == .k8B)
        #expect(CoverArt.placeholderLabelKey(seed: 24 << 4) == .k1A)
        let seeds = (0..<200).map { CoverArt.seed(artist: "Artist \($0)", title: "T") }
        #expect(Set(seeds.map(CoverArt.placeholderLabelKey(seed:))).count == 24)
    }

    /// A landscape "photo": grey, with a red square centred where the label sits.
    private func landscapeRecord() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let size = CGSize(width: 900, height: 600)
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            UIColor(white: 0.5, alpha: 1).setFill(); ctx.fill(CGRect(origin: .zero, size: size))
            UIColor(white: 0.04, alpha: 1).setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 150, y: 0, width: 600, height: 600))
            UIColor(red: 0.85, green: 0.27, blue: 0.18, alpha: 1).setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 350, y: 200, width: 200, height: 200))
        }
    }

    @Test func prepareCutsTheCentredSquareAndTheLabelCircle() throws {
        let png = try #require(landscapeRecord().pngData())
        let prepared = try #require(CoverArt.prepare(png))
        let cover = try #require(UIImage(data: prepared.cover))
        let label = try #require(UIImage(data: prepared.label))
        #expect(cover.size.width * cover.scale == 600 && cover.size.height * cover.scale == 600)
        // 0.33 of the 600 square = 198 px, under the 400 px cap.
        #expect(abs(label.size.width * label.scale - 198) <= 1)
        let (r, g, b) = rgb(try #require(prepared.color))
        #expect(r > 180 && g < 110 && b < 100, "expected the red label")
    }

    @Test func prepareHonoursAGivenSquare() throws {
        // The square placed by a crop screen (COV-2/3): its centre becomes the label.
        let image = landscapeRecord()
        let prepared = try #require(CoverArt.prepare(image, square: CGRect(x: 150, y: 0, width: 600, height: 600)))
        let (r, _, _) = rgb(try #require(prepared.color))
        #expect(r > 180)
        let offCentre = try #require(CoverArt.prepare(image, square: CGRect(x: 0, y: 0, width: 300, height: 300)))
        #expect(offCentre.color == nil || rgb(offCentre.color!).0 < 180, "a square without the label must not give red")
    }

    @Test func hexRoundTrips() throws {
        #expect(CoverArt.hex((1, 0.5, 0)) == "#FF8000")
        #expect(CoverArt.color(hex: "#FF8000") != nil)
        #expect(CoverArt.color(hex: "nope") == nil)
    }
}
