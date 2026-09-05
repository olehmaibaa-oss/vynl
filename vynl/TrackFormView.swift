//
//  TrackFormView.swift
//  vynl
//

import SwiftUI
import SwiftData

enum TrackFormMode {
    case add(release: Release)
    case edit(track: Track)
}

struct TrackFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let mode: TrackFormMode

    @State private var position = ""
    @State private var title = ""
    @State private var bpmText = ""
    @State private var key = ""

    private var isSaveEnabled: Bool {
        !position.trimmingCharacters(in: .whitespaces).isEmpty &&
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var navigationTitle: String {
        switch mode {
        case .add: return "Add Track"
        case .edit: return "Edit Track"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Required") {
                    TextField("Position", text: $position)
                        .accessibilityIdentifier("trackForm.positionField")
                    TextField("Title", text: $title)
                        .accessibilityIdentifier("trackForm.titleField")
                }
                Section("Optional") {
                    TextField("BPM", text: $bpmText)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("trackForm.bpmField")
                        .onChange(of: bpmText) { _, newValue in
                            bpmText = newValue.filter(\.isNumber)
                        }
                    TextField("Key", text: $key)
                        .accessibilityIdentifier("trackForm.keyField")
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("trackForm.cancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!isSaveEnabled)
                    .accessibilityIdentifier("trackForm.saveButton")
                }
            }
            .onAppear {
                if case .edit(let track) = mode {
                    position = track.position
                    title = track.title
                    bpmText = track.bpm.map { String($0) } ?? ""
                    key = track.key ?? ""
                }
            }
        }
    }

    private func save() {
        let trimmedPosition = position.trimmingCharacters(in: .whitespaces)
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedKey = key.trimmingCharacters(in: .whitespaces)
        let bpm = Int(bpmText)

        switch mode {
        case .add(let release):
            let track = Track(
                position: trimmedPosition,
                title: trimmedTitle,
                bpm: bpm,
                key: trimmedKey.isEmpty ? nil : trimmedKey,
                release: release
            )
            modelContext.insert(track)
        case .edit(let track):
            track.position = trimmedPosition
            track.title = trimmedTitle
            track.bpm = bpm
            track.key = trimmedKey.isEmpty ? nil : trimmedKey
        }

        dismiss()
    }
}
