//
//  ReleaseRowView.swift
//  vynl
//

import SwiftUI

struct ReleaseRowView: View {
    let release: Release

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(release.artist)
                .font(.headline)
            Text(release.title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(release.status == .owned ? "Owned" : "Sold")
                .font(.caption)
                .foregroundStyle(release.status == .owned ? Color.green : Color.secondary)
        }
        .padding(.vertical, 2)
        .accessibilityIdentifier("collection.releaseRow")
    }
}
