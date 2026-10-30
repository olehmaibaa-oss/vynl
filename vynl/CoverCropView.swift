//
//  CoverCropView.swift
//  vynl
//
//  COV-3 (SCRUM-59): fit a photo into the cover square with the record's label
//  in the centre circle. Pinch to zoom, drag to move; the photo always covers
//  the square. "Use" returns the square in the image's pixels, which
//  CoverArt.prepare turns into the cover and the label. The camera (COV-2)
//  shows its shot here too, with Retake instead of Cancel. COV-4 (SCRUM-61)
//  cleans the photo up first (CoverCleanup) and places it on its label.
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

    /// COV-4: the zoom and offset that put `square` (image pixels) under the
    /// frame, the inverse of cropRect. Clamped like a gesture would be.
    func placement(for square: CGRect) -> (zoom: CGFloat, offset: CGSize) {
        let zoom = min(max(min(imageSize.width, imageSize.height) / max(square.width, 1), 1), Self.maxZoom)
        let s = baseScale * zoom
        let raw = CGSize(width: imageSize.width * s / 2 - frameSide / 2 - square.minX * s,
                         height: imageSize.height * s / 2 - frameSide / 2 - square.minY * s)
        return (zoom, clamped(raw, zoom: zoom))
    }
}

struct CoverCropView: View {
    /// The working-size, upright photo (CoverArt.workingImage).
    let original: UIImage
    var cancelTitle = "Cancel"
    var useTitle = "Use"
    let onCancel: () -> Void
    /// The photo as cleaned up (COV-4) and the square cut from it.
    let onUse: (UIImage, CGRect) -> Void

    /// `-uitesting-noCleanup` keeps the photo as picked (deterministic UI tests).
    private static var cleanupOff: Bool { CommandLine.arguments.contains("-uitesting-noCleanup") }

    @State private var image: UIImage?
    @State private var shape: CoverCleanup.Shape?
    @State private var labelSquare: CGRect?
    @State private var options = CoverCleanup.Options()
    @State private var analysed = false
    @State private var working = false
    /// Bumped whenever the photo should be re-placed on its label.
    @State private var placeToken = 0

    @State private var zoom: CGFloat = 1
    @State private var lastZoom: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private var shown: UIImage { image ?? original }
    private var pixelSize: CGSize {
        CGSize(width: shown.size.width * shown.scale, height: shown.size.height * shown.scale)
    }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width - 32, geo.size.height - 270)
            let geometry = CropGeometry(imageSize: pixelSize, frameSide: side)
            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: shown)
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

                if working {
                    ProgressView()
                        .tint(Palette.ink)
                        .accessibilityIdentifier("coverCrop.working")
                }

                VStack {
                    HStack {
                        Button(cancelTitle, action: onCancel)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                            .accessibilityIdentifier("coverCrop.cancelButton")
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8 + ScreenInsets.top(of: geo))
                    Spacer()
                    if !Self.cleanupOff { cleanupBar }
                    Text("Fit the record in the square, the label in the circle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Palette.inkMuted)
                        .padding(.bottom, 12)
                    Button(useTitle) {
                        onUse(shown, geometry.cropRect(zoom: zoom, offset: offset))
                    }
                    .buttonStyle(.vynlPrimary)
                    .disabled(working)
                    .accessibilityIdentifier("coverCrop.useButton")
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12 + ScreenInsets.bottom(of: geo))
                }
            }
            .onChange(of: placeToken) { place(geometry) }
        }
        .preferredColorScheme(.dark)
        .task { await analyse() }
    }

    // MARK: - COV-4 cleanup

    private var cleanupBar: some View {
        HStack(spacing: 8) {
            chip("Straighten", on: options.straighten, id: "coverCrop.straightenToggle",
                 enabled: shape != nil) { options.straighten.toggle() }
            chip("Enhance", on: options.enhance, id: "coverCrop.enhanceToggle") { options.enhance.toggle() }
            chip("No background", on: options.removeBackground, id: "coverCrop.backgroundToggle") {
                options.removeBackground.toggle()
            }
            Button {
                placeToken += 1
            } label: {
                Image(systemName: "scope")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 36, height: 32)
                    .background(Capsule().stroke(Palette.ink.opacity(0.5), lineWidth: 1))
            }
            .foregroundStyle(Palette.ink)
            .disabled(labelSquare == nil || working)
            .opacity(labelSquare == nil ? 0.35 : 1)
            .accessibilityLabel("Fit label")
            .accessibilityIdentifier("coverCrop.fitLabelButton")
        }
        .padding(.bottom, 12)
        .disabled(!analysed)
        .onChange(of: options) { Task { await reprocess(replace: false) } }
    }

    private func chip(_ title: String, on: Bool, id: String, enabled: Bool = true,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Capsule().fill(on && enabled ? Palette.ink : Color.clear))
                .overlay(Capsule().stroke(Palette.ink.opacity(0.5), lineWidth: 1))
                .foregroundStyle(on && enabled ? Color.black : Palette.ink)
        }
        .disabled(!enabled || working)
        .opacity(enabled ? 1 : 0.35)
        .accessibilityIdentifier(id)
        .accessibilityValue(on && enabled ? "on" : "off")
    }

    /// First pass: find the sleeve or the record on the original, then clean up and place
    /// the photo on its label.
    private func analyse() async {
        guard !Self.cleanupOff, !analysed else { return }
        working = true
        let source = original
        shape = await Task.detached(priority: .userInitiated) { CoverCleanup.detectShape(source) }.value
        analysed = true
        await reprocess(replace: true)
    }

    private func reprocess(replace: Bool) async {
        working = true
        let source = original, found = shape, opts = options
        let result = await Task.detached(priority: .userInitiated) {
            CoverCleanup.run(source, shape: found, options: opts)
        }.value
        // A newer toggle won the race: its own pass will land.
        guard opts == options else { return }
        let sizeChanged = result.image.size != shown.size
        image = result.image
        labelSquare = result.labelSquare
        working = false
        if sizeChanged || replace { placeToken += 1 }
    }

    /// The label in the circle when one was found, otherwise centred at zoom 1.
    private func place(_ g: CropGeometry) {
        let p = labelSquare.map { g.placement(for: $0) } ?? (1, .zero)
        zoom = p.zoom; lastZoom = p.zoom
        offset = p.offset; lastOffset = p.offset
    }

    // MARK: - Gestures

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

/// The window's safe area not already applied to a full-screen cover. The
/// crop and camera covers report no safe area of their own (Appium, 29.10:
/// Cancel sat at y 8, under the status bar), so the controls pad by the
/// window's insets, minus whatever SwiftUI did apply.
enum ScreenInsets {
    private static var window: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }

    static func top(of geo: GeometryProxy) -> CGFloat {
        guard let window else { return 0 }
        return max(0, window.safeAreaInsets.top - geo.frame(in: .global).minY)
    }

    static func bottom(of geo: GeometryProxy) -> CGFloat {
        guard let window else { return 0 }
        let below = window.bounds.height - geo.frame(in: .global).maxY
        return max(0, window.safeAreaInsets.bottom - below)
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
