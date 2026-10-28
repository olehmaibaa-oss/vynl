//
//  AddReleaseView.swift
//  vynl
//

import SwiftUI
import SwiftData

enum ReleaseFormMode {
    case add
    case edit(release: Release)
}

struct AddReleaseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let mode: ReleaseFormMode

    @State private var artist = ""
    @State private var title = ""
    @State private var genreNames: [String] = []
    @State private var label = ""
    @State private var yearText = ""
    @State private var status: ReleaseStatus = .owned
    /// DR-5: already downscaled, with its label colour; written on Save only.
    @State private var cover: Data?
    @State private var coverColor: String?

    private var isSaveEnabled: Bool {
        !artist.trimmingCharacters(in: .whitespaces).isEmpty &&
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !genreNames.isEmpty  // DR-4: at least one genre
    }

    private var navigationTitle: String {
        switch mode {
        case .add: return "Add Release"
        case .edit: return "Edit Release"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cover") {
                    CoverSlot(artist: artist, title: title, cover: $cover, coverColor: $coverColor)
                }
                Section("Required") {
                    TextField("Artist", text: $artist)
                        .accessibilityIdentifier("addRelease.artistField")
                    TextField("Title", text: $title)
                        .accessibilityIdentifier("addRelease.titleField")
                }
                Section("Genres") {
                    GenrePicker(names: $genreNames)
                }
                Section("Optional") {
                    TextField("Label", text: $label)
                        .accessibilityIdentifier("addRelease.labelField")
                    TextField("Year", text: $yearText)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("addRelease.yearField")
                        .onChange(of: yearText) { _, newValue in
                            yearText = newValue.filter(\.isNumber)
                        }
                }
                if case .edit = mode {
                    Section("Status") {
                        Picker("Status", selection: $status) {
                            Text("Owned").tag(ReleaseStatus.owned)
                            Text("Sold").tag(ReleaseStatus.sold)
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("addRelease.statusPicker")
                    }
                }
            }
            .accessibilityIdentifier("addRelease.form")
            .screenBackground()
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("addRelease.cancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!isSaveEnabled)
                    .accessibilityIdentifier("addRelease.saveButton")
                }
            }
            .onAppear {
                if case .edit(let release) = mode {
                    artist = release.artist
                    title = release.title
                    genreNames = release.genreNames
                    label = release.label ?? ""
                    yearText = release.year.map { String($0) } ?? ""
                    status = release.status
                    cover = release.cover
                    coverColor = release.coverColor
                }
            }
        }
    }

    private func save() {
        // Re-filter at save time: the onChange filter can miss a keystroke under
        // fast input, and Int("19b97") would silently drop the year (SCRUM-27).
        let year = Int(yearText.filter(\.isNumber))
        let trimmedArtist = artist.trimmingCharacters(in: .whitespaces)
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedLabel = label.trimmingCharacters(in: .whitespaces)
        // Names become Genre models only now, so Cancel never leaves new genres behind.
        let genres = (try? GenreVocabulary.resolve(names: genreNames, in: modelContext)) ?? []

        switch mode {
        case .add:
            let release = Release(
                artist: trimmedArtist,
                title: trimmedTitle,
                label: trimmedLabel.isEmpty ? nil : trimmedLabel,
                year: year
            )
            modelContext.insert(release)
            release.genres = genres
            release.cover = cover
            release.coverColor = cover == nil ? nil : coverColor
        case .edit(let release):
            release.artist = trimmedArtist
            release.title = trimmedTitle
            release.genres = genres
            release.cover = cover
            release.coverColor = cover == nil ? nil : coverColor
            release.label = trimmedLabel.isEmpty ? nil : trimmedLabel
            release.year = year
            release.status = status
        }

        dismiss()
    }
}
