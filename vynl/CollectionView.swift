//
//  CollectionView.swift
//  vynl
//
//  DR-7 (SCRUM-36): one screen, two modes, grid and stack, switched from the
//  header. The chosen mode is remembered (`collectionMode`); `-uitesting`
//  launches reset it to grid so tests are deterministic, unless
//  `-uitesting-keepMode` is passed (the "mode is remembered" relaunch).
//  The release opens with a zoom transition from its sleeve in either mode.
//

import SwiftUI
import SwiftData

enum CollectionMode: String {
    case grid, stack

    static let storageKey = "collectionMode"
}

struct CollectionView: View {
    @Query(sort: \Release.artist) private var releases: [Release]
    @State private var showAddRelease = false
    @AppStorage(CollectionMode.storageKey) private var modeRaw = CollectionMode.grid.rawValue
    @Namespace private var zoom

    private var mode: CollectionMode { CollectionMode(rawValue: modeRaw) ?? .grid }

    var body: some View {
        Group {
            if releases.isEmpty {
                emptyState
            } else if mode == .grid {
                CollectionGridView(releases: releases, zoom: zoom)
            } else {
                CollectionStackView(releases: releases, zoom: zoom)
            }
        }
        .navigationDestination(for: Release.self) { release in
            ReleaseDetailView(release: release)
                .navigationTransition(.zoom(sourceID: release.persistentModelID, in: zoom))
        }
        // DR-3: every action on the right. No visible title (Collection draft v0);
        // navigationTitle stays for VoiceOver and the back button.
        .hiddenNavigationTitle()
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                modeButton(.grid, symbol: "square.grid.2x2", label: "Grid")
                modeButton(.stack, symbol: "rectangle.stack", label: "Stack")
            }
            if #available(iOS 26, *) {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink {
                    MoodVocabularyView()
                } label: {
                    Image(systemName: "gearshape")
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("Moods")
                .accessibilityIdentifier("collection.moodsButton")

                Button {
                    showAddRelease = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("Add release")
                .accessibilityIdentifier("collection.toolbarAddButton")
            }
        }
        .sheet(isPresented: $showAddRelease) {
            AddReleaseView(mode: .add)
        }
    }

    private func modeButton(_ target: CollectionMode, symbol: String, label: String) -> some View {
        let isOn = mode == target
        return Button {
            withAnimation(.easeInOut(duration: 0.25)) { modeRaw = target.rawValue }
        } label: {
            Image(systemName: symbol)
                .fontWeight(.semibold)
                .foregroundStyle(isOn ? Palette.ink : Palette.inkMuted)
        }
        .accessibilityLabel(label)
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityIdentifier(target == .grid ? "collection.gridModeButton" : "collection.stackModeButton")
    }

    private var emptyState: some View {
        // Design System EmptyState copy; the button is the DS primary (square,
        // inverted, 52pt), not a system capsule (design review 28.10).
        VynlEmptyState(title: "No records yet",
                       message: "Add your first release to start filtering and building crates.") {
            Button("Add release") { showAddRelease = true }
                .buttonStyle(.vynlPrimary)
                .accessibilityIdentifier("collection.addReleaseButton")
        }
    }
}
