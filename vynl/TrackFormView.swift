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
    /// Held in form state and written only on Save, so Cancel never leaks a change.
    @State private var selectedMoods: Set<PersistentIdentifier> = []

    @Query(sort: \MoodTag.name) private var vocabulary: [MoodTag]

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
                Section {
                    ForEach(vocabulary) { mood in
                        moodRow(mood)
                    }
                } header: {
                    Text("Moods")
                        .accessibilityIdentifier("trackForm.moodsSection")
                }
            }
            .screenBackground()
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
                    selectedMoods = Set(track.moods.map(\.persistentModelID))
                }
            }
        }
    }

    private func save() {
        let trimmedPosition = position.trimmingCharacters(in: .whitespaces)
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedKey = key.trimmingCharacters(in: .whitespaces)
        // Re-filter at save time: the onChange filter can miss a keystroke under
        // fast input, and Int("12b3") would silently drop the bpm (SCRUM-27).
        let bpm = Int(bpmText.filter(\.isNumber))

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
            track.moods = chosenMoods
        case .edit(let track):
            track.position = trimmedPosition
            track.title = trimmedTitle
            track.bpm = bpm
            track.key = trimmedKey.isEmpty ? nil : trimmedKey
            track.moods = chosenMoods
        }

        dismiss()
    }

    private var chosenMoods: [MoodTag] {
        vocabulary.filter { selectedMoods.contains($0.persistentModelID) }
    }

    /// One toggle row per mood. The checkmark is the visual state; the Selected
    /// trait is the same state for VoiceOver and UI tests.
    private func moodRow(_ mood: MoodTag) -> some View {
        let isSelected = selectedMoods.contains(mood.persistentModelID)
        return Button {
            if isSelected {
                selectedMoods.remove(mood.persistentModelID)
            } else {
                selectedMoods.insert(mood.persistentModelID)
            }
        } label: {
            HStack {
                Text(mood.name)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Palette.ink)
                }
            }
        }
        .foregroundStyle(Palette.ink)
        .accessibilityIdentifier("trackForm.mood.\(mood.name)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
