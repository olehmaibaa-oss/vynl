//
//  TrackRowView.swift
//  vynl
//
//  Design System TrackRow, as on the release screen and in the expanded stack:
//  position · title with its moods underneath · BPM · key chip. Positions and BPM
//  in tabular figures so the columns line up; a missing BPM shows a dash.
//  Accessibility: label "A1, Magneze" (identity), value = moods "Deep, Hypnotic".
//

import SwiftUI

struct TrackRowView: View {
    let track: Track

    var body: some View {
        HStack(spacing: 10) {
            Text(track.position)
                .font(.system(size: 13, weight: .bold).monospaced())
                .foregroundStyle(Palette.inkMuted)
                .frame(width: 28, alignment: .leading)
            VStack(alignment: .leading, spacing: 1) {
                Text(track.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                let moods = Self.moodLine(for: track, separator: " · ")
                if !moods.isEmpty {
                    Text(moods)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Palette.inkDim)
                        .lineLimit(1)
                        .accessibilityIdentifier("releaseDetail.trackMoods")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(track.bpm.map(String.init) ?? "—")
                .font(.system(size: 13, weight: .bold).monospaced())
                .foregroundStyle(track.bpm == nil ? Palette.inkDim : Palette.ink)
                .frame(width: 34, alignment: .trailing)
            Group {
                if track.key != nil {
                    KeyChip(key: track.key)
                } else {
                    Text("—").font(.system(size: 13, weight: .bold).monospaced()).foregroundStyle(Palette.inkDim)
                }
            }
            .frame(width: 76, alignment: .trailing)
        }
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }

    /// A track's moods, A–Z. ", " for the accessibility value, " · " on screen.
    static func moodLine(for track: Track, separator: String = ", ") -> String {
        track.moods.sortedByName().map(\.name).joined(separator: separator)
    }
}
