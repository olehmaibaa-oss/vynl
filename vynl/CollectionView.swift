//
//  CollectionView.swift
//  vynl
//

import SwiftUI
import SwiftData

struct CollectionView: View {
    @Query(sort: \Release.artist) private var releases: [Release]
    @State private var showAddRelease = false

    var body: some View {
        Group {
            if releases.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationDestination(for: Release.self) { release in
            ReleaseDetailView(release: release)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink {
                    MoodVocabularyView()
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Moods")
                .accessibilityIdentifier("collection.moodsButton")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddRelease = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier("collection.toolbarAddButton")
            }
        }
        .sheet(isPresented: $showAddRelease) {
            AddReleaseView(mode: .add)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No releases yet", systemImage: "opticaldisc")
        } description: {
            Text("Add your first record to start building your collection.")
        } actions: {
            // Primary button = inversion: ink fill (the tint), bg text.
            Button("Add Release") { showAddRelease = true }
                .buttonStyle(.borderedProminent)
                .foregroundStyle(Palette.onInvert)
                .accessibilityIdentifier("collection.addReleaseButton")
        }
        .fillBackground()
    }

    private var list: some View {
        List(releases) { release in
            NavigationLink(value: release) {
                ReleaseRowView(release: release)
            }
        }
        .screenBackground()
        .accessibilityIdentifier("collection.list")
    }
}
