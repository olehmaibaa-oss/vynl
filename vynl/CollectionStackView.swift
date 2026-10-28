//
//  CollectionStackView.swift
//  vynl
//
//  DR-7 (SCRUM-36), stack mode per Collection draft v0 and the 28.10 swipe spec:
//  - a vertical carousel of 300pt sleeves, one per swipe (view-aligned), the
//    current one centred and flat; neighbours tilt on X with the hinge on the
//    edge facing it, scale down and darken (±1: 56°, 0.92, 0.55; ±2 further);
//    Reduce Motion: neighbours only fade
//  - ambient glow in the current record's label colour
//  - the current sleeve is collapsed (plaques, "N tracks"); a tap expands it in
//    place: the sleeve shrinks up-left, the record slides out right, details and
//    the tracklist appear; "Open release" pushes the release screen. It
//    collapses on a tap on the sleeve, Hide tracks, or a swipe to another record
//  - loops (after the last comes the first) from 5 records up; with fewer, a
//    looped neighbour would be the same record twice on screen
//

import SwiftUI
import SwiftData

struct CollectionStackView: View {
    let releases: [Release]
    let zoom: Namespace.ID

    @State private var current: Int?
    @State private var expanded = false
    @Namespace private var card

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Virtual length of a looping carousel: the records repeated, starting in the middle.
    private var loops: Bool { releases.count >= 5 }
    private var slots: Int { loops ? releases.count * 200 : releases.count }
    private var startSlot: Int { loops ? releases.count * 100 : 0 }

    private func release(at slot: Int) -> Release { releases[slot % releases.count] }

    private var currentSlot: Int { current ?? startSlot }
    private var currentRelease: Release? { releases.isEmpty ? nil : release(at: min(currentSlot, slots - 1)) }

    private let spring = Animation.spring(response: 0.55, dampingFraction: 0.86)

    var body: some View {
        GeometryReader { geo in
            let side = min(300, geo.size.width - 90)
            ZStack {
                glow
                carousel(side: side, height: geo.size.height)
                    .opacity(expanded ? 0 : 1)
                    .allowsHitTesting(!expanded)
                if expanded, let release = currentRelease {
                    ExpandedRecordView(release: release, zoom: zoom, card: card,
                                       onCollapse: collapse,
                                       onSwipe: { step in collapse(); move(step) })
                        .transition(.opacity)
                }
            }
        }
        .background(Palette.bg)
        .onChange(of: releases.count) { _, _ in
            // Records came or went: back to the first, collapsed.
            expanded = false
            current = startSlot
        }
    }

    // MARK: - Carousel

    private func carousel(side: CGFloat, height: CGFloat) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 22) {
                ForEach(0..<slots, id: \.self) { slot in
                    cardView(release(at: slot), slot: slot, side: side)
                        .frame(width: side, height: side)
                        .frame(maxWidth: .infinity)
                        .id(slot)
                        .scrollTransition(.interactive, axis: .vertical) { content, phase in
                            let v = phase.value
                            let a = abs(v)
                            return content
                                .rotation3DEffect(.degrees(reduceMotion ? 0 : -60 * v),
                                                  axis: (x: 1, y: 0, z: 0),
                                                  anchor: v < 0 ? .bottom : .top,
                                                  perspective: 0.45)
                                .scaleEffect(reduceMotion ? 1 : 1 - 0.08 * a)
                                .brightness(reduceMotion ? 0 : -0.45 * a)
                                .opacity(reduceMotion ? 1 - 0.6 * a : 1)
                        }
                }
            }
            .scrollTargetLayout()
        }
        // One record per swipe, however hard the flick (swipe spec 28.10).
        .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
        .scrollPosition(id: $current, anchor: .center)
        .contentMargins(.vertical, max((height - side) / 2, 0), for: .scrollContent)
        .defaultScrollAnchor(.center)
        .onAppear { if current == nil { current = startSlot } }
        .accessibilityIdentifier("collection.stack")
    }

    private func cardView(_ release: Release, slot: Int, side: CGFloat) -> some View {
        let isCurrent = slot == currentSlot
        return Button {
            if isCurrent {
                withAnimation(spring) { expanded = true }
            } else {
                withAnimation(spring) { current = slot }
            }
        } label: {
            ZStack(alignment: .bottomLeading) {
                SleeveView(artist: release.artist, title: release.title,
                           cover: release.cover, coverColor: release.coverColor, plaques: true)
                    .matchedGeometryEffect(id: isCurrent ? "current" : "slot\(slot)", in: card,
                                           isSource: !expanded)
                    .matchedTransitionSource(id: release.persistentModelID, in: zoom)
                if isCurrent {
                    Plaque(text: "\(release.tracks.count) \(release.tracks.count == 1 ? "track" : "tracks")"
                        .uppercased(), size: 12, weight: .bold)
                        .monospaced()
                        .padding(8)
                        .transition(.opacity)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(isCurrent ? [.isButton, .isSelected] : .isButton)
        .accessibilityLabel("\(release.artist), \(release.title)")
        .accessibilityValue("\(release.tracks.count) tracks")
        .accessibilityIdentifier("collection.record")
    }

    private var glow: some View {
        let color = currentRelease.map { CoverArt.labelColor(for: $0) } ?? .clear
        return RadialGradient(colors: [color.opacity(0.42), color.opacity(0.12), .clear],
                              center: UnitPoint(x: 0.5, y: 0.45), startRadius: 0, endRadius: 380)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.6), value: currentSlot)
            .accessibilityHidden(true)
    }

    // MARK: - Moves

    private func collapse() {
        withAnimation(spring) { expanded = false }
    }

    /// One record up (−1) or down (+1), stopping at the ends unless looping.
    private func move(_ step: Int) {
        let target = currentSlot + step
        guard target >= 0, target < slots else { return }
        withAnimation(spring) { current = target }
    }
}

/// The current record, expanded in place: the sleeve shrinks up-left, the record
/// slides out to the right, then label · year, genres, Hide tracks, the
/// tracklist (scrolls inside) and Open release. Add to crate arrives with E4.
struct ExpandedRecordView: View {
    let release: Release
    let zoom: Namespace.ID
    let card: Namespace.ID
    let onCollapse: () -> Void
    let onSwipe: (Int) -> Void

    @State private var discOut = false

    private var tracks: [Track] { release.tracks.sorted { $0.position < $1.position } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topLeading) {
                RecordDisc(labelColor: CoverArt.labelColor(for: release), labelName: release.label ?? "")
                    .frame(width: 214, height: 214)
                    .rotationEffect(.degrees(discOut ? 75 : 0))
                    .offset(x: discOut ? 132 : 3, y: 3)
                // A tap gesture, not a Button: a Button would take a swipe that
                // starts on the sleeve as a tap and only collapse; a tap gesture
                // fails on movement and leaves the swipe to the view below.
                SleeveView(artist: release.artist, title: release.title,
                           cover: release.cover, coverColor: release.coverColor, plaques: true)
                    .matchedGeometryEffect(id: "current", in: card)
                    .frame(width: 220, height: 220)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onCollapse)
                    .accessibilityElement(children: .ignore)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction(.default) { onCollapse() }
                    .accessibilityLabel("\(release.artist), \(release.title)")
                    .accessibilityHint("Hides the tracks")
                    .accessibilityIdentifier("collection.expandedRecord")
            }
            .frame(maxWidth: .infinity, minHeight: 222, alignment: .topLeading)

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    let meta = [release.label, release.year.map(String.init)].compactMap { $0 }
                    if !meta.isEmpty {
                        Text(meta.joined(separator: " · ").uppercased())
                            .font(.system(size: 12, weight: .bold).monospaced())
                            .tracking(0.7)
                            .foregroundStyle(Palette.inkMuted)
                    }
                    FlowLayout(spacing: 6) {
                        ForEach(release.genreNames, id: \.self) { ChipLabel(text: $0).chipFrame() }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: onCollapse) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Palette.ink)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Palette.surface2))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Hide tracks")
                .accessibilityIdentifier("collection.hideTracksButton")
            }

            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(tracks) { track in
                        TrackRowView(track: track)
                            .padding(.horizontal, 10)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(track.position), \(track.title)")
                            .accessibilityValue(TrackRowView.moodLine(for: track))
                            .accessibilityIdentifier("collection.trackRow")
                    }
                }
            }
            .scrollIndicators(.hidden)
            .accessibilityIdentifier("collection.trackList")

            NavigationLink(value: release) {
                Text("Open release")
            }
            .buttonStyle(.vynlPrimary)
            .accessibilityIdentifier("collection.openReleaseButton")
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 30).onEnded { value in
                // Only a clear vertical swipe outside the tracklist moves on.
                guard abs(value.translation.height) > 60,
                      abs(value.translation.height) > abs(value.translation.width) else { return }
                onSwipe(value.translation.height < 0 ? 1 : -1)
            }
        )
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.18)) { discOut = true }
        }
    }
}
