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
//  - the current sleeve shows plaques and "N tracks"; a tap on it opens the
//    record sheet (SCRUM-42), a tap on a neighbour makes it current
//  - loops (after the last comes the first) from 4 records up; with 1–3 it is a
//    plain list, else the same record would show above and below (review 28.10)
//  - the current record always sits in the vertical centre between the toolbar
//    and the filter bar, the first, the last and a lone one included
//

import SwiftUI
import SwiftData

struct CollectionStackView: View {
    let releases: [Release]
    let zoom: Namespace.ID
    /// Opens the record sheet (SCRUM-42).
    let onOpen: (Release) -> Void

    @State private var current: Int?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Virtual length of a looping carousel: the records repeated, starting in the middle.
    private var loops: Bool { releases.count >= 4 }
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
            }
        }
        .background(Palette.bg)
        .onChange(of: releases.count) { _, _ in
            // Records came or went: back to the first.
            current = startSlot
        }
    }

    // MARK: - Carousel

    private func carousel(side: CGFloat, height: CGFloat) -> some View {
        ScrollViewReader { proxy in
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
        // Half the free height above the first record and below the last, so
        // view-alignment can centre every record, the ends included.
        .contentMargins(.vertical, max((height - side) / 2, 0), for: .scrollContent)
        .onAppear {
            if current == nil { current = startSlot }
            proxy.scrollTo(currentSlot, anchor: .center)
        }
        // The free height changes after the first layout (the filter bar comes
        // in with the first record); the offset doesn't follow by itself.
        .onChange(of: height) { _, _ in
            proxy.scrollTo(currentSlot, anchor: .center)
        }
        .accessibilityIdentifier("collection.stack")
        }
    }

    private func cardView(_ release: Release, slot: Int, side: CGFloat) -> some View {
        let isCurrent = slot == currentSlot
        return Button {
            if isCurrent {
                onOpen(release)
            } else {
                withAnimation(spring) { current = slot }
            }
        } label: {
            ZStack(alignment: .bottomLeading) {
                SleeveView(artist: release.artist, title: release.title,
                           cover: release.cover, coverColor: release.coverColor, labelImage: release.labelImage, plaques: true)
                    .matchedTransitionSource(id: release.persistentModelID, in: zoom)
                if isCurrent {
                    Plaque(text: Self.tracksBadge(release.tracks.count).uppercased(), size: 12, weight: .bold)
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
        .accessibilityValue(Self.tracksBadge(release.tracks.count))
        .accessibilityIdentifier("collection.record")
    }

    /// "No tracks" / "1 track" / "N tracks" (review 28.10: never "0 tracks").
    static func tracksBadge(_ count: Int) -> String {
        switch count {
        case 0: "No tracks"
        case 1: "1 track"
        default: "\(count) tracks"
        }
    }

    private var glow: some View {
        let color = currentRelease.map { CoverArt.labelColor(for: $0) } ?? .clear
        return RadialGradient(colors: [color.opacity(0.42), color.opacity(0.12), .clear],
                              center: UnitPoint(x: 0.5, y: 0.45), startRadius: 0, endRadius: 380)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.6), value: currentSlot)
            .accessibilityHidden(true)
    }

}
