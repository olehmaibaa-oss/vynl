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

    /// Longest side of a stored label image, in pixels.
    static let labelDimension: CGFloat = 400

    /// The label's diameter as a share of the record (a 12" label is ~100 mm on
    /// a ~302 mm record). The camera overlay and the library crop draw their
    /// centre circle with it, so the label lands in the same place (COV-2/3).
    static let labelRatio: CGFloat = 0.33

    /// What a picked photo turns into: the cover (the square), the label (the
    /// centre circle of that square, as a square image) and the label colour.
    struct Prepared {
        let cover: Data
        let label: Data
        let color: String?
    }

    /// From raw image data: the largest centred square (COV-1 until the crop
    /// screens of COV-2/3 let the user place it).
    static func prepare(_ data: Data) -> Prepared? {
        guard let image = UIImage(data: data) else { return nil }
        return prepare(image, square: nil)
    }

    /// From an image and the square to keep, in the image's pixel coordinates
    /// (nil: the largest centred square). The label is the centre circle of that
    /// square, `labelRatio` of its side; its colour is computed from the label.
    static func prepare(_ image: UIImage, square: CGRect?) -> Prepared? {
        let upright = normalized(image)
        guard let cg = upright.cgImage else { return nil }
        let full = CGRect(x: 0, y: 0, width: cg.width, height: cg.height)
        let rect = (square ?? centredSquare(in: full.size)).integral.intersection(full)
        guard rect.width > 0, rect.height > 0, let squareCG = cg.cropping(to: rect) else { return nil }
        let squareImage = UIImage(cgImage: squareCG)
        let labelSide = rect.width * labelRatio
        let labelRect = CGRect(x: (rect.width - labelSide) / 2, y: (rect.height - labelSide) / 2,
                               width: labelSide, height: labelSide).integral
        guard let labelCG = squareCG.cropping(to: labelRect) else { return nil }
        let labelImage = downscale(UIImage(cgImage: labelCG), maxDimension: labelDimension)
        guard let cover = downscale(squareImage, maxDimension: maxDimension).jpegData(compressionQuality: 0.82),
              let label = labelImage.jpegData(compressionQuality: 0.85) else { return nil }
        return Prepared(cover: cover, label: label, color: coverColor(of: labelImage).map(hex))
    }

    /// Longest side of the image the crop screen works on: enough for the
    /// 1200 px cover from a zoomed-in square, light enough to drag at 60 fps.
    static let workingDimension: CGFloat = 2400

    /// Decode, draw upright and scale down in one pass. Call off the main thread:
    /// a full camera or library photo takes a moment.
    nonisolated static func workingImage(from data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: workingDimension,
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: cg)
    }

    static func centredSquare(in size: CGSize) -> CGRect {
        let side = min(size.width, size.height)
        return CGRect(x: (size.width - side) / 2, y: (size.height - side) / 2, width: side, height: side)
    }

    /// Camera photos carry an orientation flag; cropping works on raw pixels, so
    /// draw them upright first.
    static func normalized(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
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

    // MARK: - coverColor (Tech Spec §2, SCRUM-41)

    /// The label colour for a photo. SCRUM-41: the DR-5 rule ("contrasts most
    /// with the average, ≥ 5% of the image") picked plain black on most photos
    /// of a record, where the black disc or a dark background dominates and the
    /// coloured centre label is a few percent of the frame. Now:
    ///
    /// 1. Vivid colours win: buckets with enough chroma, not near-black or
    ///    near-white, covering at least `minVividShare` (a centre label counts).
    ///    Score = chroma × √share, so a strong colour beats a bigger dull one.
    /// 2. The centre counts double: a photo of a record is usually centred on
    ///    its label.
    /// 3. No vivid colour (a black-and-white sleeve): the old contrast rule, but
    ///    never near-black or near-white.
    /// 4. Nothing usable: nil, so the label falls back to the placeholder's key
    ///    colour instead of black.
    ///
    /// The image is reduced to 48×48 and bucketed at 3 bits per channel; a
    /// bucket's colour is the mean of its pixels.
    static func coverColor(of image: UIImage, minVividShare: Double = 0.012,
                           minShare: Double = 0.05) -> (r: Double, g: Double, b: Double)? {
        let side = 48
        guard let pixels = rgbPixels(of: image, side: side), !pixels.isEmpty else { return nil }
        var buckets: [Int: (n: Double, r: Double, g: Double, b: Double)] = [:]
        var sum = (r: 0.0, g: 0.0, b: 0.0), total = 0.0
        let c = Double(side - 1) / 2, centreRadius = Double(side) * 0.25
        for (i, p) in pixels.enumerated() {
            let x = Double(i % side) - c, y = Double(i / side) - c
            let w = (x * x + y * y).squareRoot() <= centreRadius ? 2.0 : 1.0
            sum.r += p.r * w; sum.g += p.g * w; sum.b += p.b * w; total += w
            let key = (Int(p.r * 7.999) << 6) | (Int(p.g * 7.999) << 3) | Int(p.b * 7.999)
            let cur = buckets[key] ?? (0, 0, 0, 0)
            buckets[key] = (cur.n + w, cur.r + p.r * w, cur.g + p.g * w, cur.b + p.b * w)
        }
        let average = (r: sum.r / total, g: sum.g / total, b: sum.b / total)
        let colours = buckets.values.map { (colour: mean($0), share: $0.n / total) }

        let vivid = colours.filter { $0.share >= minVividShare && isVivid($0.colour) }
        if let best = vivid.max(by: { chroma($0.colour) * $0.share.squareRoot() < chroma($1.colour) * $1.share.squareRoot() }) {
            return best.colour
        }
        let usable = colours.filter { $0.share >= minShare && !isNearBlackOrWhite($0.colour) }
        return usable.max { distance($0.colour, average) < distance($1.colour, average) }?.colour
    }

    static func chroma(_ c: (r: Double, g: Double, b: Double)) -> Double {
        max(c.r, c.g, c.b) - min(c.r, c.g, c.b)
    }

    static func luma(_ c: (r: Double, g: Double, b: Double)) -> Double {
        0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
    }

    /// Saturated enough to read as a colour, and neither black nor white.
    static func isVivid(_ c: (r: Double, g: Double, b: Double)) -> Bool {
        chroma(c) >= 0.18 && !isNearBlackOrWhite(c)
    }

    static func isNearBlackOrWhite(_ c: (r: Double, g: Double, b: Double)) -> Bool {
        let l = luma(c)
        return l < 0.12 || (l > 0.9 && chroma(c) < 0.12)
    }

    private static func mean(_ b: (n: Double, r: Double, g: Double, b: Double)) -> (r: Double, g: Double, b: Double) {
        (b.r / b.n, b.g / b.n, b.b / b.n)
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
