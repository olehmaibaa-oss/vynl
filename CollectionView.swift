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
            Button("Add Release") { showAddRelease = true }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("collection.addReleaseButton")
        }
    }

    private var list: some View {
        List(releases) { release in
            NavigationLink(value: release) {
                ReleaseRowView(release: release)
            }
        }
        .accessibilityIdentifier("collection.list")
    }
}
