//
//  CratesPlaceholderView.swift
//  vynl
//
//  Stand-in for the Crates zone until E4. The tab exists now so the app's
//  navigation shape matches the Tech Spec; its content arrives with E4.
//

import SwiftUI

struct CratesPlaceholderView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Crates are on the way", systemImage: "archivebox")
        } description: {
            Text("Pick records for a gig and mark the tracks you'll play.")
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("crates.placeholder")
        .fillBackground()
    }
}

#Preview {
    NavigationStack {
        CratesPlaceholderView()
            .navigationTitle("Crates")
    }
}
