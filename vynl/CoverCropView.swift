//
//  CoverCropView.swift
//  vynl
//
//  COV-3 (SCRUM-59): fit a photo into the cover square with the record's label
//  in the centre circle. Pinch to zoom, drag to move; the photo always covers
//  the square. "Use" returns the square in the image's pixels, which
//  CoverArt.prepare turns into the cover and the label. The camera (COV-2)
//  shows its shot here too, with Retake instead of Cancel.
//

import SwiftUI

/// The crop maths, kept free of SwiftUI so it can be unit-tested.
struct CropGeometry {
    /// The (upright) image size in pixels.
    let imageSize: CGSize
    /// The on-screen side of the square frame, in points.
    let frameSide: CGFloat

    static let maxZoom: CGFloat = 5

    /// Points per image pixel at zoom 1: the image's short side fills the frame.
    var baseScale: CGFloat { frameSide / min(imageSize.width, imageSize.height) }

    /// The furthest the image can move from centre at `zoom` without leaving
    /// part of the square uncovered.
    func maxOffset(zoom: CGFloat) -> CGSize {
        let s = baseScale * zoom
        return CGSize(width: max(0, (imageSize.width * s - frameSide) / 2),
                      height: max(0, (imageSize.height * s - frameSide) / 2))
    }

    func clamped(_ offset: CGSize, zoom: CGFloat) -> CGSize {
        let m = maxOffset(zoom: zoom)
        return CGSize(width: min(max(offset.width, -m.width), m.width),
                      height: min(max(offset.height, -m.height), m.height))
    }

    /// The square under the frame, in image pixels. `offset` moves the image
    /// (positive = right/down), so the crop moves the other way.
    func cropRect(zoom: CGFloat, offset: CGSize) -> CGRect {
        let s = baseScale * zoom
        let o = clamped(offset, zoom: zoom)
        let side = frameSide / s
        let x = (imageSize.width * s / 2 - frameSide / 2 - o.width) / s
        let y = (imageSize.height * s / 2 - frameSide / 2 - o.height) / s
        return CGRect(x: x, y: y, width: side, height: side)
    }
}

struct CoverCropView: View {
    let image: UIImage
    var cancelTitle = "Cancel"
    var useTitle = "Use"
    let onCancel: () -> Void
    let onUse: (CGRect) -> Void

    @State private var zoom: CGFloat = 1
    @State private var lastZoom: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // The caller hands over a working-size, upright image
    // (CoverArt.workingImage); nothing is redrawn while dragging.
    private var upright: UIImage { image }
    private var pixelSize: CGSize {
        CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
    }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width - 32, geo.size.height - 220)
            let geometry = CropGeometry(imageSize: pixelSize, frameSide: side)
            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: upright)
                    .resizable()
                    .frame(width: pixelSize.width * geometry.baseScale * zoom,
                           height: pixelSize.height * geometry.baseScale * zoom)
                    .offset(offset)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .contentShape(Rectangle())
                    .gesture(dragGesture(geometry).simultaneously(with: zoomGesture(geometry)))
                    .accessibilityElement()
                    .accessibilityLabel("Photo")
                    .accessibilityHint("Drag to move, pinch to zoom")
                    .accessibilityIdentifier("coverCrop.view")

                CropOverlay(side: side)
                    .allowsHitTesting(false)

                VStack {
                    HStack {
                        Button(cancelTitle, action: onCancel)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                            .accessibilityIdentifier("coverCrop.cancelButton")
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    Spacer()
                    Text("Fit the record in the square, the label in the circle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Palette.inkMuted)
                        .padding(.bottom, 12)
                    Button(useTitle) {
                        onUse(geometry.cropRect(zoom: zoom, offset: offset))
                    }
                    .buttonStyle(.vynlPrimary)
                    .accessibilityIdentifier("coverCrop.useButton")
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func dragGesture(_ g: CropGeometry) -> some Gesture {
        DragGesture()
            .onChanged { v in
                offset = g.clamped(CGSize(width: lastOffset.width + v.translation.width,
                                          height: lastOffset.height + v.translation.height), zoom: zoom)
            }
            .onEnded { _ in lastOffset = offset }
    }

    private func zoomGesture(_ g: CropGeometry) -> some Gesture {
        MagnifyGesture()
            .onChanged { v in
                zoom = min(max(lastZoom * v.magnification, 1), CropGeometry.maxZoom)
                offset = g.clamped(offset, zoom: zoom)
            }
            .onEnded { _ in
                lastZoom = zoom
                lastOffset = offset
            }
    }
}

/// The square frame and the label circle over a dimmed surround. Shared with
/// the camera (COV-2), so both give the same cover and label.
struct CropOverlay: View {
    let side: CGFloat

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(x: (geo.size.width - side) / 2, y: (geo.size.height - side) / 2,
                              width: side, height: side)
            let labelSide = side * CoverArt.labelRatio
            ZStack {
                Path { p in
                    p.addRect(CGRect(origin: .zero, size: geo.size))
                    p.addRect(rect)
                }
                .fill(Color.black.opacity(0.6), style: FillStyle(eoFill: true))
                Rectangle()
                    .stroke(Palette.ink, lineWidth: 1.5)
                    .frame(width: side, height: side)
                    .position(x: rect.midX, y: rect.midY)
                Circle()
                    .stroke(Palette.ink.opacity(0.9), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .frame(width: labelSide, height: labelSide)
                    .position(x: rect.midX, y: rect.midY)
            }
        }
        // Same geometry as the photo (no ignoresSafeArea here): the frame drawn
        // is the square that gets cut. It used to ignore the safe area while the
        // photo didn't, so the frame sat off the real crop (PO, 29.10).
        .accessibilityHidden(true)
    }
}
