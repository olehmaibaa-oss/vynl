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

    @Test func picksTheContrastingAccent() throws {
        // Dark teal cover with a cream band (20%): cream contrasts with the average.
        let img = image(base: UIColor(red: 0.11, green: 0.31, blue: 0.35, alpha: 1),
                        accent: UIColor(red: 0.93, green: 0.89, blue: 0.81, alpha: 1), share: 0.2)
        let hex = CoverArt.hex(try #require(CoverArt.coverColor(of: img)))
        let (r, g, b) = rgb(hex)
        #expect(r > 200 && g > 190 && b > 170, "expected cream, got \(hex)")
    }

    @Test func ignoresColoursUnderFivePercent() throws {
        // A bright red sliver at 2% would contrast most, but it's too small to count.
        let img = image(base: UIColor(white: 0.1, alpha: 1), accent: .red, share: 0.02)
        let hex = CoverArt.hex(try #require(CoverArt.coverColor(of: img)))
        let (r, g, _) = rgb(hex)
        #expect(!(r > 200 && g < 60), "the 2% red won: \(hex)")
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

    @Test func hexRoundTrips() throws {
        #expect(CoverArt.hex((1, 0.5, 0)) == "#FF8000")
        #expect(CoverArt.color(hex: "#FF8000") != nil)
        #expect(CoverArt.color(hex: "nope") == nil)
    }
}
