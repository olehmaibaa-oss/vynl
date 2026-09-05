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
    @State private var genre = ""
    @State private var label = ""
    @State private var yearText = ""
    @State private var status: ReleaseStatus = .owned

    private var isSaveEnabled: Bool {
        !artist.trimmingCharacters(in: .whitespaces).isEmpty &&
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !genre.trimmingCharacters(in: .whitespaces).isEmpty
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
                Section("Required") {
                    TextField("Artist", text: $artist)
                        .accessibilityIdentifier("addRelease.artistField")
                    TextField("Title", text: $title)
                        .accessibilityIdentifier("addRelease.titleField")
                    TextField("Genre", text: $genre)
                        .accessibilityIdentifier("addRelease.genreField")
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
                    genre = release.genre
                    label = release.label ?? ""
                    yearText = release.year.map { String($0) } ?? ""
                    status = release.status
                }
            }
        }
    }

    private func save() {
        let trimmedArtist = artist.trimmingCharacters(in: .whitespaces)
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedGenre = genre.trimmingCharacters(in: .whitespaces)
        let trimmedLabel = label.trimmingCharacters(in: .whitespaces)

        switch mode {
        case .add:
            let release = Release(
                artist: trimmedArtist,
                title: trimmedTitle,
                genre: trimmedGenre,
                label: trimmedLabel.isEmpty ? nil : trimmedLabel,
                year: Int(yearText)
            )
            modelContext.insert(release)
        case .edit(let release):
            release.artist = trimmedArtist
            release.title = trimmedTitle
            release.genre = trimmedGenre
            release.label = trimmedLabel.isEmpty ? nil : trimmedLabel
            release.year = Int(yearText)
            release.status = status
        }

        dismiss()
    }
}
