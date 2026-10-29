//
//  CoverSlot.swift
//  vynl
//
//  DR-5 (SCRUM-34): the cover in the release form. The sleeve updates live as
//  artist and title are typed (the placeholder is computed, never stored).
//  Library through PhotosPicker (no permission prompt for picking), camera only
//  where there is one, Remove when a cover is set. A picked photo is downscaled
//  and its coverColor computed here, before the form saves it.
//

import SwiftUI
import AVFoundation
import PhotosUI
import UIKit

struct CoverSlot: View {
    let artist: String
    let title: String
    @Binding var cover: Data?
    @Binding var coverColor: String?

    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showCameraDenied = false

    /// `-uitesting-noCamera` lets a UI test see the app as on a device without a
    /// camera (the iOS 26 simulator reports one).
    private var hasCamera: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
            && !CommandLine.arguments.contains("-uitesting-noCamera")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            SleeveView(artist: artist.isEmpty ? "Artist" : artist,
                       title: title.isEmpty ? "Title" : title,
                       cover: cover, coverColor: coverColor, dieCut: false, plaques: true)
                .frame(width: 120, height: 120)
                .accessibilityIdentifier("addRelease.coverSlot")

            VStack(alignment: .leading, spacing: 4) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("Choose photo", systemImage: "photo.on.rectangle")
                }
                .accessibilityIdentifier("addRelease.libraryButton")

                if hasCamera {
                    Button {
                        openCamera()
                    } label: {
                        Label("Take photo", systemImage: "camera")
                    }
                    .accessibilityIdentifier("addRelease.cameraButton")
                }

                if cover != nil {
                    Button("Remove cover", role: .destructive) {
                        cover = nil
                        coverColor = nil
                        pickerItem = nil
                    }
                    .foregroundStyle(Palette.danger)
                    .accessibilityIdentifier("addRelease.removeCoverButton")
                }
            }
            .buttonStyle(.borderless)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Palette.ink)
            .labelStyle(.titleAndIcon)
        }
        .padding(.vertical, 6)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    apply(data)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                if let data = image.jpegData(compressionQuality: 0.9) { apply(data) }
            }
            .ignoresSafeArea()
        }
        .alert("Camera access is off", isPresented: $showCameraDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Choose photo instead", role: .cancel) {}
        } message: {
            Text("Allow camera access for VYNL in Settings to photograph a cover, or pick a photo from your library.")
        }
    }

    /// SCRUM-40: asks for camera access first. Denied or restricted: an alert
    /// pointing to Settings instead of a black camera screen.
    private func openCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    if granted { showCamera = true } else { showCameraDenied = true }
                }
            }
        default:
            showCameraDenied = true
        }
    }

    private func apply(_ data: Data) {
        guard let prepared = CoverArt.prepare(data) else { return }
        cover = prepared.cover
        coverColor = prepared.color
    }
}

/// The system camera. Only offered when the device has one (never on the simulator).
struct CameraPicker: UIViewControllerRepresentable {
    let onPick: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onPick(image) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
