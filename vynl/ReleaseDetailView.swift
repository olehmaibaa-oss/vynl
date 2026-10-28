//
//  ReleaseDetailView.swift
//  vynl
//
//  DR-5 (SCRUM-34): the release screen as drawn 28.10 (Tech Spec §3). A 220pt
//  die-cut sleeve top left with the record slid out to the right (the expanded
//  stack's state, so DR-7's zoom transition continues it), title, artist,
//  LABEL · YEAR · STATUS, genre chips, TRACKS with a count over a hairline,
//  the Design System track rows, outline "Add track", text "Delete release".
//
//  Still a List (plain, no chrome) rather than a ScrollView: it keeps
//  swipe-to-delete on track rows, and `releaseDetail.view` stays the scroll
//  view tests scope their lookups to.
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

    private var labelColor: Color { CoverArt.labelColor(for: release) }

    var body: some View {
        List {
            hero
                .plainRow(top: 8, bottom: 20)
            details
                .plainRow(bottom: 16)
            tracksHeader
                .plainRow(bottom: 0)
            ForEach(sortedTracks) { track in
                Button {
                    editingTrack = track
                } label: {
                    TrackRowView(track: track)
                }
                .buttonStyle(.plain)
                // Label stays the track's identity ("A1, Magneze"); the moods are
                // its value, so anything matching on the label stays stable.
                .accessibilityElement(children: .ignore)
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("\(track.position), \(track.title)")
                .accessibilityValue(TrackRowView.moodLine(for: track))
                .accessibilityIdentifier("releaseDetail.trackRow")
                .plainRow(bottom: 0)
            }
            .onDelete(perform: deleteTracks)

            Button {
                showAddTrack = true
            } label: {
                Label("Add track", systemImage: "plus")
            }
            .buttonStyle(.vynlSecondary)
            .accessibilityIdentifier("releaseDetail.addTrackButton")
            .plainRow(top: 16, bottom: 8)

            Button("Delete release") {
                showDeleteConfirmation = true
            }
            .buttonStyle(.vynlDestructive)
            .accessibilityIdentifier("releaseDetail.deleteButton")
            .plainRow(bottom: 40)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(alignment: .top) {
            // Ambient glow in the label colour behind the sleeve.
            ZStack {
                Palette.bg
                RadialGradient(colors: [labelColor.opacity(0.32), labelColor.opacity(0.08), .clear],
                               center: UnitPoint(x: 0.4, y: 0.2), startRadius: 0, endRadius: 360)
            }
            .ignoresSafeArea()
        }
        .accessibilityIdentifier("releaseDetail.view")
        .navigationTitle(release.title)
        .hiddenNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddTrack = true
                } label: {
                    Image(systemName: "plus").fontWeight(.semibold)
                }
                .accessibilityLabel("Add track")
                .accessibilityIdentifier("releaseDetail.toolbarAddTrackButton")
            }
            ToolbarItem(placement: .topBarTrailing) {
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
        .alert("Delete release?", isPresented: $showDeleteConfirmation) {
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

    // MARK: - Pieces

    /// The sleeve, 220pt, with the record slid out to its right.
    private var hero: some View {
        ZStack(alignment: .topLeading) {
            RecordDisc(labelColor: labelColor, labelName: release.label ?? "")
                .frame(width: 214, height: 214)
                .offset(x: 132, y: 3)
            SleeveView(artist: release.artist, title: release.title,
                       cover: release.cover, coverColor: release.coverColor)
                .frame(width: 220, height: 220)
                .accessibilityIdentifier("releaseDetail.cover")
        }
        .frame(maxWidth: .infinity, minHeight: 222, alignment: .topLeading)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(release.title)
                .font(.system(size: 30, weight: .heavy))
                .tracking(-0.3)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("releaseDetail.title")
            Text(release.artist)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .accessibilityIdentifier("releaseDetail.artist")
            Text(metaLine)
                .font(.system(size: 12, weight: .bold).monospaced())
                .tracking(0.7)
                .foregroundStyle(Palette.inkMuted)
                .padding(.top, 4)
                // Spoken and tested field by field; empty optionals read "—".
                .accessibilityLabel(metaAccessibility)
                .accessibilityIdentifier("releaseDetail.meta")
            if !release.genreNames.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(release.genreNames, id: \.self) { name in
                        ChipLabel(text: name)
                            .chipFrame()
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(name)
                            .accessibilityIdentifier("releaseDetail.genreChip")
                    }
                }
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tracksHeader: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("TRACKS")
                    .tracking(1)
                    .foregroundStyle(Palette.inkMuted)
                Spacer()
                Text("\(sortedTracks.count)")
                    .foregroundStyle(Palette.inkDim)
            }
            .font(.system(size: 12, weight: .bold).monospaced())
            Rectangle().fill(Palette.line).frame(height: 1)
        }
        .accessibilityElement(children: .combine)
    }

    /// "LOW HUM · 2019 · OWNED"; parts that aren't there are left out.
    private var metaLine: String {
        [release.label, release.year.map(String.init), statusText]
            .compactMap { $0 }
            .joined(separator: " · ")
            .uppercased()
    }

    private var statusText: String { release.status == .owned ? "Owned" : "Sold" }

    private var metaAccessibility: String {
        "Label, \(release.label ?? "—"); Year, \(release.year.map(String.init) ?? "—"); Status, \(statusText)"
    }

    private func deleteTracks(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedTracks[index])
        }
    }
}

private extension View {
    /// A List row with no chrome: clear background, no separator, 16pt gutters.
    func plainRow(top: CGFloat = 0, bottom: CGFloat = 0) -> some View {
        listRowInsets(EdgeInsets(top: top, leading: 16, bottom: bottom, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
