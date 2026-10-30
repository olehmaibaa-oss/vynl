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

    /// Position → title of the tracks already on this release, the edited
    /// track left out (the first one wins on a duplicate).
    private var otherTracks: [String: String] {
        let tracks: [Track]
        switch mode {
        case .add(let release): tracks = release.tracks
        case .edit(let track): tracks = (track.release?.tracks ?? []).filter { $0 !== track }
        }
        var map: [String: String] = [:]
        for t in tracks.sorted(by: { $0.position < $1.position }) where map[t.position] == nil {
            map[t.position] = t.title
        }
        return map
    }

    private var editingPosition: String? {
        if case .edit(let track) = mode { return track.position }
        return nil
    }

    private var navigationTitle: String {
        switch mode {
        case .add: return "Add track"
        case .edit: return "Edit track"
        }
    }

    var body: some View {
        NavigationStack {
            // SCRUM-64: the designer's track form. Labelled blocks on the
            // sheet's surface instead of grouped Form rows.
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    PositionPicker(position: $position, tracks: otherTracks,
                                   title: title, editing: editingPosition)

                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel("Title")
                        TextField("Track title", text: $title)
                            .font(.system(size: 17))
                            .fieldBlock()
                            .accessibilityIdentifier("trackForm.titleField")
                    }

                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            FieldLabel("BPM")
                            TextField("—", text: $bpmText)
                                .font(.system(size: 17, weight: .bold, design: .monospaced))
                                .keyboardType(.numberPad)
                                .fieldBlock()
                                .accessibilityIdentifier("trackForm.bpmField")
                                .onChange(of: bpmText) { _, newValue in
                                    bpmText = newValue.filter(\.isNumber)
                                }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            FieldLabel("Key")
                            // DR-6: picked on the Camelot wheel, pushed (no sheet on a sheet).
                            NavigationLink {
                                CamelotPickerView(selection: $key)
                            } label: {
                                HStack(spacing: 8) {
                                    if key != nil {
                                        KeyChip(key: key)
                                    } else {
                                        Text("Choose").font(.system(size: 17)).foregroundStyle(Palette.inkDim)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Palette.inkDim)
                                }
                                .fieldBlock(horizontal: 12)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(key?.display ?? "Key")
                            .accessibilityIdentifier("trackForm.keyButton")
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        FieldLabel("Moods")
                        // E2-S6: grouped chips, one block per mood group.
                        MoodPicker(selection: $selectedMoods)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Palette.surface)
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
                if case .add(let release) = mode {
                    position = TrackPosition.nextFree(after: release.tracks.map(\.position))
                }
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

        modelContext.persist()
        dismiss()
    }

    private var chosenMoods: [MoodTag] {
        vocabulary.filter { selectedMoods.contains($0.persistentModelID) }
    }
}

private extension View {
    /// The DS field: a `surface-2` block with a hairline `line` edge, 48 pt.
    func fieldBlock(horizontal: CGFloat = 14) -> some View {
        padding(.horizontal, horizontal)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .background(Palette.surface2)
            .overlay(Rectangle().strokeBorder(Palette.line, lineWidth: 1))
    }
}
