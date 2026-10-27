//
//  ReleaseDetailView.swift
//  vynl
//

import SwiftUI
import SwiftData

struct ReleaseDetailView: View {
    let release: Release

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showAddTrack = false
    @State private var editingTrack: Track? = nil
    @State private var showEditRelease = false
    @State private var showDeleteConfirmation = false

    private var sortedTracks: [Track] {
        release.tracks.sorted { $0.position < $1.position }
    }

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Artist", value: release.artist)
                LabeledContent("Title", value: release.title)
                LabeledContent("Genre", value: release.genre)
                LabeledContent("Status", value: release.status == .owned ? "Owned" : "Sold")
                LabeledContent("Label", value: release.label ?? "—")
                LabeledContent("Year", value: release.year.map { String($0) } ?? "—")
            }

            Section("Tracks") {
                if sortedTracks.isEmpty {
                    Button {
                        showAddTrack = true
                    } label: {
                        Label("Add Track", systemImage: "plus.circle")
                    }
                    .accessibilityIdentifier("releaseDetail.addTrackButton")
                } else {
                    ForEach(sortedTracks) { track in
                        Button {
                            editingTrack = track
                        } label: {
                            HStack(alignment: .firstTextBaseline) {
                                Text(track.position)
                                    .font(.caption)
                                    .foregroundStyle(Palette.inkMuted)
                                    .frame(minWidth: 32, alignment: .leading)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(track.title)
                                        .foregroundStyle(Palette.ink)
                                    let moods = moodLine(for: track)
                                    if !moods.isEmpty {
                                        Text(moods)
                                            .font(.caption)
                                            .foregroundStyle(Palette.inkMuted)
                                            .accessibilityIdentifier("releaseDetail.trackMoods")
                                    }
                                }
                            }
                        }
                        // Label stays the track's identity ("A1, Magneze"); the
                        // moods are its value. VoiceOver reads both, and the
                        // label stays stable for anything that matches on it.
                        .accessibilityLabel("\(track.position), \(track.title)")
                        .accessibilityValue(moodLine(for: track))
                        .accessibilityIdentifier("releaseDetail.trackRow")
                    }
                    .onDelete(perform: deleteTracks)
                }
            }

            Section {
                Button("Delete Release", role: .destructive) {
                    showDeleteConfirmation = true
                }
                .foregroundStyle(Palette.danger)
                .accessibilityIdentifier("releaseDetail.deleteButton")
            }
        }
        .screenBackground()
        .accessibilityIdentifier("releaseDetail.view")
        .navigationTitle(release.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddTrack = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier("releaseDetail.toolbarAddTrackButton")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showEditRelease = true
                }
                .accessibilityIdentifier("releaseDetail.editButton")
            }
        }
        .sheet(isPresented: $showAddTrack) {
            TrackFormView(mode: .add(release: release))
        }
        .sheet(item: $editingTrack) { track in
            TrackFormView(mode: .edit(track: track))
        }
        .sheet(isPresented: $showEditRelease) {
            AddReleaseView(mode: .edit(release: release))
        }
        .alert("Delete Release?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(release)
                dismiss()
            }
            .accessibilityIdentifier("releaseDetail.confirmDeleteButton")
            Button("Cancel", role: .cancel) { }
                .accessibilityIdentifier("releaseDetail.cancelDeleteButton")
        } message: {
            Text("This will permanently delete the release and all its tracks.")
        }
    }

    /// A track's moods, A–Z, comma-separated. Empty when it has none.
    private func moodLine(for track: Track) -> String {
        track.moods.map(\.name).sorted().joined(separator: ", ")
    }

    private func deleteTracks(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedTracks[index])
        }
    }
}
