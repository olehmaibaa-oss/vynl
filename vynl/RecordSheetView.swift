//
//  RecordSheetView.swift
//  vynl
//
//  SCRUM-42 (design decision 29.10, canvas "Record sheet", Tech Spec v7 §3):
//  tapping a record in either mode opens this sheet instead of expanding it in
//  place. ~85% high over the dimmed collection, draggable to full height; closes
//  with × or a swipe down. Sleeve with the record sliding out, title, artist,
//  label · year, genres, TRACKS, the tracklist ("No tracks yet" when empty) and
//  a pinned Open release, which dismisses the sheet and pushes the release
//  screen. Add to crate arrives with E4.
//

import SwiftUI

struct RecordSheetView: View {
    let release: Release
    let onOpenRelease: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var discOut = false

    private var tracks: [Track] { release.tracks.sorted { $0.position < $1.position } }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    hero
                    details
                    tracksSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 28)
                // Room for the pinned button.
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)

            openRelease
        }
        .overlay(alignment: .topTrailing) { closeButton }
        .background(Palette.surface)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(release.artist), \(release.title)")
        .accessibilityIdentifier("recordSheet")
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) { discOut = true }
        }
    }

    // MARK: - Parts

    private var hero: some View {
        ZStack(alignment: .topLeading) {
            RecordDisc(labelColor: CoverArt.labelColor(for: release), labelName: release.label ?? "",
                       labelImage: release.cover == nil ? nil : release.labelImage)
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(discOut ? 75 : 0))
                .offset(x: discOut ? 104 : 4, y: 4)
            SleeveView(artist: release.artist, title: release.title,
                       cover: release.cover, coverColor: release.coverColor, labelImage: release.labelImage)
                .frame(width: 168, height: 168)
                .shadow(color: .black.opacity(0.7), radius: 20, y: 20)
        }
        .frame(maxWidth: .infinity, minHeight: 176, alignment: .topLeading)
        .padding(.bottom, 8)
        .accessibilityHidden(true)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(release.title)
                    .font(.system(size: 28, weight: .heavy))
                    .tracking(-0.3)
                    .foregroundStyle(Palette.ink)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("recordSheet.title")
                Text(release.artist)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .accessibilityIdentifier("recordSheet.artist")
                let meta = [release.label, release.year.map(String.init)].compactMap { $0 }
                if !meta.isEmpty {
                    Text(meta.joined(separator: " · ").uppercased())
                        .font(.system(size: 12, weight: .bold).monospaced())
                        .tracking(0.7)
                        .foregroundStyle(Palette.inkMuted)
                        .padding(.top, 2)
                }
            }
            if !release.genreNames.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(release.genreNames, id: \.self) { ChipLabel(text: $0).chipFrame() }
                }
            }
        }
    }

    private var tracksSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text("TRACKS")
                    .font(.system(size: 12, weight: .bold).monospaced())
                    .tracking(1)
                    .foregroundStyle(Palette.inkMuted)
                Spacer()
                Text("\(tracks.count)")
                    .font(.system(size: 12, weight: .bold).monospaced())
                    .foregroundStyle(Palette.inkDim)
            }
            .padding(.top, 6)
            .padding(.bottom, 8)
            .overlay(alignment: .bottom) { Rectangle().fill(Palette.line).frame(height: 1) }
            .padding(.bottom, 4)

            if tracks.isEmpty {
                // Tracks are added on the release screen (Open release).
                Text("No tracks yet")
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.inkMuted)
                    .padding(.top, 8)
                    .accessibilityIdentifier("recordSheet.noTracks")
            } else {
                ForEach(tracks) { track in
                    TrackRowView(track: track)
                        .padding(.horizontal, 10)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(track.position), \(track.title)")
                        .accessibilityValue(TrackRowView.moodLine(for: track))
                        .accessibilityIdentifier("recordSheet.trackRow")
                }
            }
        }
    }

    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.ink)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Palette.surface2))
        }
        .buttonStyle(.plain)
        .padding(.top, 16)
        .padding(.trailing, 16)
        .accessibilityLabel("Close")
        .accessibilityIdentifier("recordSheet.closeButton")
    }

    private var openRelease: some View {
        Button("Open release", action: onOpenRelease)
            .buttonStyle(.vynlPrimary)
            .accessibilityIdentifier("recordSheet.openReleaseButton")
            .padding(.horizontal, 16)
            .padding(.top, 28)
            .padding(.bottom, 12)
            .background(
                LinearGradient(stops: [.init(color: Palette.surface.opacity(0), location: 0),
                                       .init(color: Palette.surface, location: 0.35)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
    }
}
