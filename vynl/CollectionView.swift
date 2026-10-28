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
        // DR-3: every action on the right, in one group. The grid/stack toggle joins
        // it in DR-7. No visible title (Collection draft v0); navigationTitle stays
        // for VoiceOver and the back button.
        .hiddenNavigationTitle()
        .toolbar {
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
