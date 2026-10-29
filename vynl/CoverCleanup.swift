//
//  CoverCleanup.swift
//  vynl
//
//  COV-4 (SCRUM-61): tidy a cover photo on-device before the crop, with what
//  iOS ships: Vision finds the sleeve (rectangle) and the record's label
//  (contours + our circle fit), Core Image straightens and auto-enhances, and
//  Vision's foreground mask removes the background. Everything here is pure and
//  runs off the main thread on the working image (≤ 2400 px).
//

import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

enum CoverCleanup {

    /// A detected sleeve: its corners in image pixels, Core Image orientation
    /// (origin bottom-left).
    nonisolated struct Quad: Equatable, Sendable {
        let topLeft, topRight, bottomRight, bottomLeft: CGPoint
    }

    /// A detected label: centre and radius in image pixels, origin top-left.
    nonisolated struct Circle: Equatable, Sendable {
        let center: CGPoint
        let radius: CGFloat
    }

    nonisolated struct Options: Equatable, Sendable {
        var straighten = true
        var enhance = true
        var removeBackground = false
    }

    nonisolated(unsafe) private static let context = CIContext(options: [.useSoftwareRenderer: false])

    /// One run of the pipeline: the photo to crop and where its label is.
    nonisolated struct Result: Sendable {
        let image: UIImage
        /// The crop square that centres the label in the circle; nil when no
        /// label was found.
        let labelSquare: CGRect?
    }

    // MARK: - Pipeline

    /// Process + find the label in the result. Off the main thread.
    nonisolated static func run(_ image: UIImage, sleeve: Quad?, options: Options) -> Result {
        let out = process(image, sleeve: sleeve, options: options)
        let size = CGSize(width: out.size.width * out.scale, height: out.size.height * out.scale)
        let square = detectLabel(out).map { self.square(around: $0, in: size) }
        return Result(image: out, labelSquare: square)
    }

    /// Original → straightened (when asked and a sleeve was found) → background
    /// removed (when asked) → enhanced (when asked).
    nonisolated static func process(_ image: UIImage, sleeve: Quad?, options: Options) -> UIImage {
        var result = image
        if options.straighten, let sleeve, let straight = straightened(result, quad: sleeve) { result = straight }
        if options.removeBackground, let cut = backgroundRemoved(result) { result = cut }
        if options.enhance, let better = enhanced(result) { result = better }
        return result
    }

    // MARK: - Sleeve

    /// The biggest roughly square quadrilateral covering at least ~30% of the
    /// photo: a sleeve. Nil when there's none.
    nonisolated static func detectSleeve(_ image: UIImage) -> Quad? {
        guard let cg = image.cgImage else { return nil }
        let request = VNDetectRectanglesRequest()
        request.minimumAspectRatio = 0.75
        request.maximumAspectRatio = 1
        request.minimumSize = 0.3
        request.quadratureTolerance = 25
        request.minimumConfidence = 0.6
        request.maximumObservations = 1
        try? VNImageRequestHandler(cgImage: cg).perform([request])
        guard let r = request.results?.first else { return nil }
        let w = CGFloat(cg.width), h = CGFloat(cg.height)
        func px(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * w, y: p.y * h) }
        return Quad(topLeft: px(r.topLeft), topRight: px(r.topRight),
                    bottomRight: px(r.bottomRight), bottomLeft: px(r.bottomLeft))
    }

    /// The sleeve, perspective-corrected and stretched to a square.
    nonisolated static func straightened(_ image: UIImage, quad: Quad) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = CIImage(cgImage: cg)
        filter.topLeft = quad.topLeft
        filter.topRight = quad.topRight
        filter.bottomRight = quad.bottomRight
        filter.bottomLeft = quad.bottomLeft
        guard let out = filter.outputImage else { return nil }
        let side = max(out.extent.width, out.extent.height)
        let square = out
            .transformed(by: CGAffineTransform(translationX: -out.extent.minX, y: -out.extent.minY))
            .transformed(by: CGAffineTransform(scaleX: side / out.extent.width, y: side / out.extent.height))
        return render(square, size: CGSize(width: side, height: side))
    }

    // MARK: - Enhance

    /// Core Image's own auto adjustments (exposure, white balance, contrast,
    /// vibrance), no red-eye.
    nonisolated static func enhanced(_ image: UIImage) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        var ci = CIImage(cgImage: cg)
        for filter in ci.autoAdjustmentFilters(options: [.redEye: false]) {
            filter.setValue(ci, forKey: kCIInputImageKey)
            if let out = filter.outputImage { ci = out }
        }
        return render(ci, size: CGSize(width: cg.width, height: cg.height))
    }

    // MARK: - Background

    /// Everything but the main subject (Vision's foreground mask) goes black.
    nonisolated static func backgroundRemoved(_ image: UIImage) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cg)
        guard (try? handler.perform([request])) != nil,
              let result = request.results?.first,
              let buffer = try? result.generateMaskedImage(ofInstances: result.allInstances, from: handler,
                                                           croppedToInstancesExtent: false) else { return nil }
        let subject = CIImage(cvPixelBuffer: buffer)
        let black = CIImage(color: .black).cropped(to: subject.extent)
        return render(subject.composited(over: black), size: subject.extent.size)
    }

    // MARK: - Label

    /// The record's label: the most circular closed contour whose radius is a
    /// plausible label (6–30% of the short side), the nearest the centre
    /// winning ties. Nil when nothing round enough is found.
    nonisolated static func detectLabel(_ image: UIImage) -> Circle? {
        guard let cg = image.cgImage else { return nil }
        let w = CGFloat(cg.width), h = CGFloat(cg.height), short = min(w, h)
        let request = VNDetectContoursRequest()
        request.contrastAdjustment = 2
        request.maximumImageDimension = 512
        try? VNImageRequestHandler(cgImage: cg).perform([request])
        guard let observation = request.results?.first else { return nil }

        var best: (circle: Circle, score: CGFloat)?
        for contour in allContours(observation) where contour.pointCount >= 24 {
            // Normalized, origin bottom-left → pixels, origin top-left.
            let points = contour.normalizedPoints.map { CGPoint(x: CGFloat($0.x) * w, y: (1 - CGFloat($0.y)) * h) }
            let n = CGFloat(points.count)
            let c = CGPoint(x: points.reduce(0) { $0 + $1.x } / n, y: points.reduce(0) { $0 + $1.y } / n)
            let radii = points.map { hypot($0.x - c.x, $0.y - c.y) }
            let mean = radii.reduce(0, +) / n
            guard mean >= short * 0.06, mean <= short * 0.3 else { continue }
            let spread = (radii.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / n).squareRoot() / mean
            guard spread < 0.08 else { continue }
            let offCentre = hypot(c.x - w / 2, c.y - h / 2) / short
            let score = spread + offCentre * 0.2
            if best == nil || score < best!.score { best = (Circle(center: c, radius: mean), score) }
        }
        return best?.circle
    }

    private nonisolated static func allContours(_ observation: VNContoursObservation) -> [VNContour] {
        var out: [VNContour] = []
        func walk(_ c: VNContour) {
            out.append(c)
            c.childContours.forEach(walk)
        }
        observation.topLevelContours.forEach(walk)
        return out
    }

    /// The crop square that puts `label` in the centre circle at its size
    /// (CoverArt.labelRatio), clamped to the image.
    nonisolated static func square(around label: Circle, in size: CGSize) -> CGRect {
        let side = min(label.radius * 2 / CoverArt.labelRatio, min(size.width, size.height))
        let x = min(max(label.center.x - side / 2, 0), size.width - side)
        let y = min(max(label.center.y - side / 2, 0), size.height - side)
        return CGRect(x: x, y: y, width: side, height: side)
    }

    // MARK: -

    private nonisolated static func render(_ ci: CIImage, size: CGSize) -> UIImage? {
        let rect = CGRect(origin: ci.extent.origin, size: size)
        guard let cg = context.createCGImage(ci, from: rect) else { return nil }
        return UIImage(cgImage: cg)
    }
}
