//
//  RecordCameraView.swift
//  vynl
//
//  COV-2 (SCRUM-58): our own camera for photographing a record. A square
//  preview (the cover crop) with the dashed label circle in the centre: line
//  the record up, the label in the circle, shoot. The shot then opens the crop
//  screen (COV-3) at the same square, with Retake / Use photo.
//
//  The preview is a square with aspect-fill, so it shows exactly the centred
//  square of the photo, which is the crop screen's starting square: what you
//  framed is what you get.
//

import AVFoundation
import Combine
import SwiftUI

final class RecordCamera: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    // Touched on `queue` only (AVFoundation's rule), never from the main actor.
    nonisolated(unsafe) let session = AVCaptureSession()
    nonisolated(unsafe) private let output = AVCapturePhotoOutput()
    nonisolated private let queue = DispatchQueue(label: "dev.vynl.camera")
    private var onPhoto: ((UIImage) -> Void)?

    @Published var flash: AVCaptureDevice.FlashMode = .auto
    @Published private(set) var hasFlash = false
    @Published private(set) var isReady = false

    func start() {
        queue.async { [self] in
            if session.inputs.isEmpty { configure() }
            if !session.isRunning { session.startRunning() }
            DispatchQueue.main.async { self.isReady = self.session.isRunning }
        }
    }

    func stop() {
        queue.async { [self] in
            if session.isRunning { session.stopRunning() }
        }
    }

    nonisolated private func configure() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        defer { session.commitConfiguration() }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input), session.canAddOutput(output) else { return }
        session.addInput(input)
        session.addOutput(output)
        output.maxPhotoQualityPrioritization = .quality
        let flash = device.hasFlash
        DispatchQueue.main.async { self.hasFlash = flash }
    }

    func capture(_ done: @escaping (UIImage) -> Void) {
        onPhoto = done
        let mode = flash
        queue.async { [self] in
            let settings = AVCapturePhotoSettings()
            if output.supportedFlashModes.contains(mode) { settings.flashMode = mode }
            // Portrait only: the sensor is landscape, so rotate the shot upright.
            if let connection = output.connection(with: .video), connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
            output.capturePhoto(with: settings, delegate: self)
        }
    }

    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto,
                                 error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation() else { return }
        Task { @MainActor in
            guard let image = UIImage(data: data) else { return }
            self.onPhoto?(image)
            self.onPhoto = nil
        }
    }
}

/// The live preview, aspect-filled into whatever frame it's given.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        if let connection = view.previewLayer.connection, connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        return view
    }

    func updateUIView(_ view: PreviewView, context: Context) {
        if let connection = view.previewLayer.connection, connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
    }
}

struct RecordCameraView: View {
    let onShot: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = RecordCamera()
    @State private var shooting = false

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width - 32, geo.size.height - 260)
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 16) {
                    topBar
                    Spacer(minLength: 0)
                    ZStack {
                        CameraPreview(session: camera.session)
                        Rectangle().stroke(Palette.ink, lineWidth: 1.5)
                        Circle()
                            .stroke(Palette.ink.opacity(0.9), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                            .frame(width: side * CoverArt.labelRatio, height: side * CoverArt.labelRatio)
                    }
                    .frame(width: side, height: side)
                    .clipped()
                    .accessibilityElement()
                    .accessibilityLabel("Camera preview")
                    .accessibilityIdentifier("recordCamera.preview")
                    Text("Fit the record in the square, the label in the circle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Palette.inkMuted)
                    Spacer(minLength: 0)
                    shutter
                        .padding(.bottom, 24)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Close")
            .accessibilityIdentifier("recordCamera.closeButton")
            Spacer()
            if camera.hasFlash {
                Button { cycleFlash() } label: {
                    Image(systemName: flashSymbol)
                        .font(.system(size: 17, weight: .bold))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Flash")
                .accessibilityValue(flashName)
                .accessibilityIdentifier("recordCamera.flashButton")
            }
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    private var shutter: some View {
        Button {
            guard !shooting else { return }
            shooting = true
            camera.capture { image in
                onShot(image)
                dismiss()
            }
        } label: {
            ZStack {
                Circle().stroke(Palette.ink, lineWidth: 4).frame(width: 76, height: 76)
                Circle().fill(Palette.ink).frame(width: 62, height: 62)
                    .opacity(shooting ? 0.4 : 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!camera.isReady)
        .accessibilityLabel("Take photo")
        .accessibilityIdentifier("recordCamera.shutterButton")
    }

    private func cycleFlash() {
        switch camera.flash {
        case .auto: camera.flash = .on
        case .on: camera.flash = .off
        default: camera.flash = .auto
        }
    }

    private var flashSymbol: String {
        switch camera.flash {
        case .on: "bolt.fill"
        case .off: "bolt.slash.fill"
        default: "bolt.badge.automatic.fill"
        }
    }

    private var flashName: String {
        switch camera.flash {
        case .on: "On"
        case .off: "Off"
        default: "Auto"
        }
    }
}
