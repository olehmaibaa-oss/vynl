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

        var area: CGFloat {
            let p = [topLeft, topRight, bottomRight, bottomLeft]
            var sum: CGFloat = 0
            for i in 0..<4 { sum += p[i].x * p[(i + 1) % 4].y - p[(i + 1) % 4].x * p[i].y }
            return abs(sum) / 2
        }
    }

    /// A detected label: centre and radius in image pixels, origin top-left.
    nonisolated struct Circle: Equatable, Sendable {
        let center: CGPoint
        let radius: CGFloat
    }

    /// A record seen at an angle: an ellipse in image pixels, origin top-left,
    /// `angle` of the major axis in radians.
    nonisolated struct Ellipse: Equatable, Sendable {
        let center: CGPoint
        let a, b: CGFloat
        let angle: CGFloat
    }

    /// What can be straightened: a sleeve (4 corners) or a bare record.
    nonisolated enum Shape: Equatable, Sendable {
        case sleeve(Quad)
        case record(Ellipse)
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
    nonisolated static func run(_ image: UIImage, shape: Shape?, options: Options) -> Result {
        let out = process(image, shape: shape, options: options)
        let size = CGSize(width: out.size.width * out.scale, height: out.size.height * out.scale)
        let square = detectLabel(out).map { self.square(around: $0, in: size) }
        return Result(image: out, labelSquare: square)
    }

    /// Original → straightened (when asked and a sleeve or record was found) →
    /// background removed (when asked) → enhanced (when asked).
    nonisolated static func process(_ image: UIImage, shape: Shape?, options: Options) -> UIImage {
        var result = image
        if options.straighten, let shape {
            let straight: UIImage?
            switch shape {
            case .sleeve(let quad): straight = straightened(result, quad: quad)
            case .record(let ellipse): straight = straightened(result, record: ellipse)
            }
            if let straight { result = straight }
        }
        if options.removeBackground, let cut = backgroundRemoved(result) { result = cut }
        if options.enhance, let better = enhanced(result) { result = better }
        return result
    }

    // MARK: - Shape

    /// A sleeve when there's one, otherwise a bare record.
    nonisolated static func detectShape(_ image: UIImage) -> Shape? {
        let quad = detectSleeve(image), ellipse = detectRecord(image)
        // A bare record also passes as a rough quad (its bounding box): when
        // the ellipse fills most of the quad, it's the record.
        if let ellipse, quad == nil || .pi * ellipse.a * ellipse.b >= quad!.area * 0.5 { return .record(ellipse) }
        return quad.map { .sleeve($0) }
    }

    // MARK: - Sleeve

    /// The biggest quadrilateral covering at least ~25% of the photo: a sleeve,
    /// squashed up to 2:1 by the angle it was shot at. Nil when there's none.
    nonisolated static func detectSleeve(_ image: UIImage) -> Quad? {
        guard let cg = image.cgImage else { return nil }
        let request = VNDetectRectanglesRequest()
        request.minimumAspectRatio = 0.5
        request.maximumAspectRatio = 1
        request.minimumSize = 0.25
        request.quadratureTolerance = 40
        request.minimumConfidence = 0.4
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

    // MARK: - Record

    /// The biggest closed contour that is an ellipse (its points within ~5% of
    /// the fitted ellipse, axes no flatter than 2:1) covering at least 15% of
    /// the photo: the record. Fitted from the contour's area moments.
    nonisolated static func detectRecord(_ image: UIImage) -> Ellipse? {
        guard let cg = image.cgImage else { return nil }
        let w = CGFloat(cg.width), h = CGFloat(cg.height)
        let request = VNDetectContoursRequest()
        request.contrastAdjustment = 2
        request.maximumImageDimension = 512
        try? VNImageRequestHandler(cgImage: cg).perform([request])
        guard let observation = request.results?.first else { return nil }

        var best: (ellipse: Ellipse, area: CGFloat)?
        for contour in allContours(observation) where contour.pointCount >= 40 {
            let pts = contour.normalizedPoints.map { CGPoint(x: CGFloat($0.x) * w, y: (1 - CGFloat($0.y)) * h) }
            guard let fitted = fitEllipse(pts), fitted.area >= w * h * 0.15 else { continue }
            let ellipse = fitted.0, area = fitted.area
            guard ellipse.b / ellipse.a >= 0.5, deviation(pts, from: ellipse) < 0.05 else { continue }
            if best == nil || area > best!.area { best = (ellipse, area) }
        }
        return best?.ellipse
    }

    /// Mean distance of the points from the ellipse, as a share of its radius
    /// in their direction. A rectangle's corners push this to ~0.1.
    nonisolated static func deviation(_ pts: [CGPoint], from e: Ellipse) -> CGFloat {
        let c = cos(e.angle), s = sin(e.angle)
        let total = pts.reduce(CGFloat(0)) { sum, p in
            let dx = p.x - e.center.x, dy = p.y - e.center.y
            let u = dx * c + dy * s, v = -dx * s + dy * c
            return sum + abs(((u * u) / (e.a * e.a) + (v * v) / (e.b * e.b)).squareRoot() - 1)
        }
        return total / CGFloat(max(pts.count, 1))
    }

    /// The ellipse with the same area moments as the polygon: for a filled
    /// ellipse the covariance is diag(a²/4, b²/4).
    nonisolated static func fitEllipse(_ p: [CGPoint]) -> (Ellipse, area: CGFloat)? {
        guard p.count >= 3 else { return nil }
        var a2 = 0.0, cx = 0.0, cy = 0.0, ixx = 0.0, iyy = 0.0, ixy = 0.0
        for i in p.indices {
            let p0 = p[i], p1 = p[(i + 1) % p.count]
            let x0 = Double(p0.x), y0 = Double(p0.y), x1 = Double(p1.x), y1 = Double(p1.y)
            let cross = x0 * y1 - x1 * y0
            a2 += cross
            cx += (x0 + x1) * cross
            cy += (y0 + y1) * cross
            ixx += (x0 * x0 + x0 * x1 + x1 * x1) * cross
            iyy += (y0 * y0 + y0 * y1 + y1 * y1) * cross
            ixy += (x0 * y1 + 2 * x0 * y0 + 2 * x1 * y1 + x1 * y0) * cross
        }
        let area = a2 / 2
        guard abs(area) > 1 else { return nil }
        cx /= 6 * area; cy /= 6 * area
        let mxx = ixx / 12 / area - cx * cx
        let myy = iyy / 12 / area - cy * cy
        let mxy = ixy / 24 / area - cx * cy
        let root = (((mxx - myy) / 2) * ((mxx - myy) / 2) + mxy * mxy).squareRoot()
        let l1 = (mxx + myy) / 2 + root, l2 = (mxx + myy) / 2 - root
        guard l2 > 0 else { return nil }
        let angle: Double = 0.5 * atan2(2 * mxy, mxx - myy)
        let ellipse = Ellipse(center: CGPoint(x: CGFloat(cx), y: CGFloat(cy)),
                              a: CGFloat(2 * l1.squareRoot()), b: CGFloat(2 * l2.squareRoot()),
                              angle: CGFloat(angle))
        return (ellipse, CGFloat(abs(area)))
    }

    /// The record made round again (stretched along its minor axis) and cut to
    /// a square around it with a little margin.
    nonisolated static func straightened(_ image: UIImage, record e: Ellipse) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let h = CGFloat(cg.height)
        // Core Image: origin bottom-left, so y and the angle flip.
        let c = CGPoint(x: e.center.x, y: h - e.center.y)
        let theta = -e.angle
        let t = CGAffineTransform(translationX: -c.x, y: -c.y)
            .concatenating(CGAffineTransform(rotationAngle: -theta))
            .concatenating(CGAffineTransform(scaleX: 1, y: e.a / e.b))
            .concatenating(CGAffineTransform(rotationAngle: theta))
            .concatenating(CGAffineTransform(translationX: c.x, y: c.y))
        let round = CIImage(cgImage: cg).transformed(by: t)
        let side = (e.a * 2 * 1.06).rounded()
        let square = CGRect(x: c.x - side / 2, y: c.y - side / 2, width: side, height: side)
        let black = CIImage(color: .black).cropped(to: square)
        let out = round.composited(over: black).cropped(to: square)
            .transformed(by: CGAffineTransform(translationX: -square.minX, y: -square.minY))
        return render(out, size: square.size)
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
