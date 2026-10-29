//
//  CollectionView.swift
//  vynl
//
//  DR-7 (SCRUM-36): one screen, two modes, grid and stack, switched from the
//  header. The chosen mode is remembered (`collectionMode`); `-uitesting`
//  launches reset it to grid so tests are deterministic, unless
//  `-uitesting-keepMode` is passed (the "mode is remembered" relaunch).
//  The release opens with a zoom transition from its sleeve in either mode.
//  DR-8 (SCRUM-37): both modes follow the sort chosen in the filter sheet
//  (`collectionSort`, artist A–Z by default), reached from the filter bar.
//

import SwiftUI
import SwiftData

enum CollectionMode: String {
    case grid, stack

    static let storageKey = "collectionMode"
}

struct CollectionView: View {
    @Query private var releases: [Release]
    @State private var showAddRelease = false
    @State private var showFilter = false
    /// The record whose sheet is up (SCRUM-42), in either mode.
    @State private var sheetRelease: Release?
    /// Set by Open release; pushed once the sheet is gone.
    @State private var releaseToOpen: Release?
    @State private var pushedRelease: Release?
    @AppStorage(RecordSort.storageKey) private var sortRaw = RecordSort.default.rawValue
    @AppStorage(CollectionMode.storageKey) private var modeRaw = CollectionMode.grid.rawValue
    @Namespace private var zoom

    private var mode: CollectionMode { CollectionMode(rawValue: modeRaw) ?? .grid }

    private var sort: RecordSort { RecordSort(rawValue: sortRaw) ?? .default }
    private var sortBinding: Binding<RecordSort> {
        Binding(get: { sort }, set: { sortRaw = $0.rawValue })
    }

    var body: some View {
        Group {
            if releases.isEmpty {
                emptyState
            } else if mode == .grid {
                CollectionGridView(releases: sort.sorted(releases), zoom: zoom) { sheetRelease = $0 }
            } else {
                // A new order starts the stack again from its first record.
                CollectionStackView(releases: sort.sorted(releases), zoom: zoom) { sheetRelease = $0 }
                    .id(sortRaw)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !releases.isEmpty {
                FilterBar(count: releases.count, sort: sort) { showFilter = true }
            }
        }
        .sheet(isPresented: $showFilter) {
            FilterSheet(sort: sortBinding)
        }
        .sheet(item: $sheetRelease, onDismiss: {
            // Open release: the sheet goes first, then the release screen is pushed.
            if let release = releaseToOpen {
                releaseToOpen = nil
                pushedRelease = release
            }
        }) { release in
            RecordSheetView(release: release) {
                releaseToOpen = release
                sheetRelease = nil
            }
            // No zoom: with a partial detent iOS fades the sheet in instead of
            // zooming, which read as "it just appears" on a device (PO, 29.10).
            // The standard slide up from the bottom; the record still slides
            // out of the sleeve inside.
            .presentationDetents([.fraction(0.85), .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Palette.surface)
            .presentationCornerRadius(34)
        }
        .navigationDestination(item: $pushedRelease) { release in
            ReleaseDetailView(release: release)
        }
        // DR-3: every action on the right. No visible title (Collection draft v0);
        // navigationTitle stays for VoiceOver and the back button.
        .hiddenNavigationTitle()
        .toolbar {
            // Nothing to switch while the collection is empty (canvas "Collection · empty").
            if !releases.isEmpty {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    modeButton(.grid, symbol: "square.grid.2x2", label: "Grid")
                    modeButton(.stack, symbol: "rectangle.stack", label: "Stack")
                }
                if #available(iOS 26, *) {
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                }
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
        // Canvas "Collection · empty" (28.10): empty sleeve outline with a faint
        // record behind, copy, the DS primary button full width. Same in both
        // modes; the toggle and the filter bar are hidden while empty.
        VynlEmptyState(title: "No records yet",
                       message: "Add a record with its cover and tracks, then dig through it here by BPM, key and mood.") {
            EmptySleeveArt()
        } actions: {
            Button("Add release") { showAddRelease = true }
                .buttonStyle(.vynlPrimary)
                .accessibilityIdentifier("collection.addReleaseButton")
        }
        .background {
            // Faint ink glow behind the sleeve.
            RadialGradient(colors: [Palette.ink.opacity(0.06), Palette.ink.opacity(0)],
                           center: UnitPoint(x: 0.5, y: 0.36), startRadius: 0, endRadius: 260)
                .ignoresSafeArea()
                .accessibilityHidden(true)
        }
        .background(Palette.bg)
    }
}
