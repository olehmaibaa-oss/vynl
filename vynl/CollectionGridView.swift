//
//  CollectionGridView.swift
//  vynl
//
//  DR-7 (SCRUM-36), grid mode as drawn 28.10 (Tech Spec §3): 2 columns, 16 at the
//  edges, 12 between columns, 24 between rows. A tile is the die-cut sleeve with
//  its label (no disc, no plaques), title (15) and artist (13, ink-muted) under
//  it, one line each. A tap opens the release with the zoom transition.
//

import SwiftUI
import SwiftData

struct CollectionGridView: View {
    let releases: [Release]
    let zoom: Namespace.ID

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(releases) { release in
                    NavigationLink(value: release) {
                        tile(release)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("\(release.artist), \(release.title)")
                    .accessibilityIdentifier("collection.record")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollContentBackground(.hidden)
        .background(Palette.bg)
        .accessibilityIdentifier("collection.grid")
    }

    private func tile(_ release: Release) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SleeveView(artist: release.artist, title: release.title,
                       cover: release.cover, coverColor: release.coverColor)
                .matchedTransitionSource(id: release.persistentModelID, in: zoom)
            VStack(alignment: .leading, spacing: 1) {
                Text(release.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                Text(release.artist)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.inkMuted)
            }
            .lineLimit(1)
        }
    }
}
