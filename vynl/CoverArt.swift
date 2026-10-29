//
//  CoverArt.swift
//  vynl
//
//  DR-5 (SCRUM-34): the image side of covers, no UI.
//  - prepare(): downscale a picked photo before it is stored (12 MP per record
//    would not survive 500 records) and compute its coverColor.
//  - labelColor(): the colour seen through the sleeve's die-cut. For a photo it
//    is the stored coverColor; a placeholder derives one from its seed.
//  - Seed: djb2 of "artist—title" (Design System Sleeve), so the same release
//    always gets the same generated sleeve.
//

import UIKit
import SwiftUI

enum CoverArt {

    /// Longest side of a stored cover, in pixels.
    static let maxDimension: CGFloat = 1200

    // MARK: - Saving a picked photo

    /// Downscaled JPEG and its label colour, ready to store on the release.
    static func prepare(_ data: Data) -> (cover: Data, color: String?)? {
        guard let image = UIImage(data: data) else { return nil }
        let scaled = downscale(image, maxDimension: maxDimension)
        guard let jpeg = scaled.jpegData(compressionQuality: 0.82) else { return nil }
        return (jpeg, coverColor(of: scaled).map(hex))
    }

    static func downscale(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height) * image.scale
        guard longest > maxDimension else { return image }
        let ratio = maxDimension / longest
        let target = CGSize(width: (size.width * image.scale * ratio).rounded(),
                            height: (size.height * image.scale * ratio).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }

    // MARK: - coverColor (Tech Spec §2)

    /// Among the colours that cover at least `minShare` of the image, the one
    /// that differs most from the image's average colour. Nil for an image that
    /// can't be read.
    ///
    /// The image is reduced to 32×32 and its pixels are bucketed at 3 bits per
    /// channel; a bucket's colour is the mean of its pixels. "Differs most" is the
    /// Euclidean distance in RGB, which is enough to pick a contrasting accent.
    static func coverColor(of image: UIImage, minShare: Double = 0.05) -> (r: Double, g: Double, b: Double)? {
        guard let pixels = rgbPixels(of: image, side: 32), !pixels.isEmpty else { return nil }
        var buckets: [Int: (n: Int, r: Double, g: Double, b: Double)] = [:]
        var sum = (r: 0.0, g: 0.0, b: 0.0)
        for p in pixels {
            sum.r += p.r; sum.g += p.g; sum.b += p.b
            let key = (Int(p.r * 7.999) << 6) | (Int(p.g * 7.999) << 3) | Int(p.b * 7.999)
            let cur = buckets[key] ?? (0, 0, 0, 0)
            buckets[key] = (cur.n + 1, cur.r + p.r, cur.g + p.g, cur.b + p.b)
        }
        let count = Double(pixels.count)
        let average = (r: sum.r / count, g: sum.g / count, b: sum.b / count)
        let big = buckets.values.filter { Double($0.n) / count >= minShare }
        let candidates = big.isEmpty ? Array(buckets.values) : big
        let best = candidates.max { a, b in
            distance(mean(a), average) < distance(mean(b), average)
        }
        return best.map(mean)
    }

    private static func mean(_ b: (n: Int, r: Double, g: Double, b: Double)) -> (r: Double, g: Double, b: Double) {
        (b.r / Double(b.n), b.g / Double(b.n), b.b / Double(b.n))
    }

    private static func distance(_ a: (r: Double, g: Double, b: Double), _ b: (r: Double, g: Double, b: Double)) -> Double {
        let dr = a.r - b.r, dg = a.g - b.g, db = a.b - b.b
        return dr * dr + dg * dg + db * db
    }

    private static func rgbPixels(of image: UIImage, side: Int) -> [(r: Double, g: Double, b: Double)]? {
        guard let cg = image.cgImage else { return nil }
        var raw = [UInt8](repeating: 0, count: side * side * 4)
        guard let ctx = CGContext(data: &raw, width: side, height: side, bitsPerComponent: 8,
                                  bytesPerRow: side * 4, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.interpolationQuality = .medium
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: side, height: side))
        var pixels: [(r: Double, g: Double, b: Double)] = []
        pixels.reserveCapacity(side * side)
        for i in stride(from: 0, to: raw.count, by: 4) {
            let r = Double(raw[i]) / 255
            let g = Double(raw[i + 1]) / 255
            let b = Double(raw[i + 2]) / 255
            pixels.append((r, g, b))
        }
        return pixels
    }

    static func hex(_ c: (r: Double, g: Double, b: Double)) -> String {
        String(format: "#%02X%02X%02X", Int((c.r * 255).rounded()), Int((c.g * 255).rounded()), Int((c.b * 255).rounded()))
    }

    static func color(hex: String) -> Color? {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        return Color(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255,
                     blue: Double(v & 0xFF) / 255)
    }

    // MARK: - Placeholder (Design System Sleeve)

    /// djb2 over the UTF-8 of "artist—title".
    static func seed(artist: String, title: String) -> UInt32 {
        var hash: UInt32 = 5381
        for byte in "\(artist)—\(title)".utf8 {
            hash = (hash &<< 5) &+ hash &+ UInt32(byte)
        }
        return hash
    }

    /// The key whose colour a placeholder's label takes: one of the 24 Camelot
    /// keys, picked by the seed (design, SCRUM-34 28.10).
    static func placeholderLabelKey(seed: UInt32) -> CamelotKey {
        CamelotKey.allCases[Int((seed >> 4) % UInt32(CamelotKey.allCases.count))]
    }

    /// The label colour of a placeholder: a Camelot key colour from the seed.
    static func placeholderLabelColor(seed: UInt32) -> Color {
        Palette.key(placeholderLabelKey(seed: seed).code)
    }

    /// What shows through the die-cut for this release.
    static func labelColor(for release: Release) -> Color {
        labelColor(artist: release.artist, title: release.title, coverColor: release.cover == nil ? nil : release.coverColor)
    }

    static func labelColor(artist: String, title: String, coverColor: String?) -> Color {
        if let hex = coverColor, let c = color(hex: hex) { return c }
        return placeholderLabelColor(seed: seed(artist: artist, title: title))
    }
}
