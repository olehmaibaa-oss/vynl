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
    @State private var key: CamelotKey?
    @State private var loaded = false
    /// Held in form state and written only on Save, so Cancel never leaks a change.
    @State private var selectedMoods: Set<PersistentIdentifier> = []

    @Query private var allMoods: [MoodTag]
    private var vocabulary: [MoodTag] { allMoods.sortedByName() }

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
                    // DR-6: picked on the Camelot wheel, pushed (no sheet on a sheet).
                    NavigationLink {
                        CamelotPickerView(selection: $key)
                    } label: {
                        HStack {
                            Text("Key").foregroundStyle(key == nil ? Palette.inkDim : Palette.ink)
                            Spacer()
                            if key != nil { KeyChip(key: key) }
                        }
                    }
                    .accessibilityLabel(key?.display ?? "Key")
                    .accessibilityIdentifier("trackForm.keyButton")
                }
                // E2-S6: grouped chips (one section per mood group) instead of
                // 30 toggle rows.
                MoodPicker(selection: $selectedMoods)
            }
            .screenBackground()
            // The form's scroll view, so a test scrolls this list and not the
            // release screen behind the sheet or the keyboard's suggestion bar.
            .accessibilityIdentifier("trackForm.form")
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
                // Load once. onAppear fires again when the key picker is popped,
                // and reloading then would throw away what was just edited,
                // including a cleared key (found by camelot.feature, DR-6).
                guard !loaded else { return }
                loaded = true
                if case .edit(let track) = mode {
                    position = track.position
                    title = track.title
                    bpmText = track.bpm.map { String($0) } ?? ""
                    key = track.key
                    selectedMoods = Set(track.moods.map(\.persistentModelID))
                }
            }
        }
    }

    private func save() {
        let trimmedPosition = position.trimmingCharacters(in: .whitespaces)
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let camelotKey = key
        // Re-filter at save time: the onChange filter can miss a keystroke under
        // fast input, and Int("12b3") would silently drop the bpm (SCRUM-27).
        let bpm = Int(bpmText.filter(\.isNumber))

        switch mode {
        case .add(let release):
            let track = Track(
                position: trimmedPosition,
                title: trimmedTitle,
                bpm: bpm,
                key: camelotKey,
                release: release
            )
            modelContext.insert(track)
            track.moods = chosenMoods
        case .edit(let track):
            track.position = trimmedPosition
            track.title = trimmedTitle
            track.bpm = bpm
            track.key = camelotKey
            track.moods = chosenMoods
        }

        dismiss()
    }

    private var chosenMoods: [MoodTag] {
        vocabulary.filter { selectedMoods.contains($0.persistentModelID) }
    }
}
